#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"
require "yaml"
require "pp"

# BIG FAT WARNING:
# you ***HAVE TO*** modify 'cygtempdir' to reflect the directory
# where cygwin has downloaded its temporary files!

CYGWIN_SETUPRCFILE = "/etc/setup/setup.rc"

GOODFIELDS = /^(sdesc|category|requires):/i

module Util
  def self.rmquotes(str, typ='"')
    firstch = str[0]
    lastch = str[str.length - 1]
    if (firstch == typ) then
      tmp = str[1 .. str.length]
      if lastch == typ then
        tmp = tmp[0 .. (tmp.length - 2)]
      #else
        ## maybe... warn the user?
      end
      return tmp
    end
    return str
  end
end

class CygPackages
  def initialize(opts)
    @opts = opts
    @installedpkgs = []
    @localconf = File.join(ENV["HOME"], "/.cygpackages.yml")
    @progname = File.basename($0)
    @we_just_updated = false
    @searchboth = (
      ((@opts.onlypkgname == false) && (@opts.onlydescript == false)) &&
      ((@opts.findpkgname.empty? && opts.finddescript.empty?))
    )

    # load config, regardless if it's being updated ...
    @confdata = get_localconf
    # might still be using the old format
    @prevpkgcount = (if @confdata.key?(:meta) then @confdata[:meta][:count] else 0 end)

    # force update if our local config doesn't exist yet
    if not File.file?(@localconf) then
      update(true)
      @confdata = get_localconf
    end
    if @opts.want_update then
      if (@we_just_updated == false)
        update(true)
        @confdata = get_localconf
      end
    end
=begin
Cygwin Package Information
Package                               Version
_autorebase                           001007-1
a2ps                                  4.14-3
adwaita-icon-theme                    3.26.1-1
adwaita-themes                        3.22.3-1
alternatives                          1.3.30c-10
arc                                   5.21q-1
arj                                   3.10.22-3
=end
    if @opts.wantinstalled then
      IO.popen(["cygcheck", "-c", "-d"]) do |fh|
        # first two lines are useless
        fh.readline; fh.readline
        fh.each_line do |line|
          pkgname, ver = line.split(/\s/).map(&:strip).reject(&:empty?)
          #$stderr.printf("cygcheck: pkgname=%p\n", pkgname)
          @installedpkgs.push(pkgname)
        end
      end
    end
  end

  def msg(fmt, *args)
    str = (if args.empty? then fmt else sprintf(fmt, *args) end)
    $stderr.printf("-- %s\n", str)
  end

  def main(args)
    success = 0
    packages = @confdata[:packages]
    pkgcount = packages.size
    rxflags = ((@opts.ignorecase == true) ? Regexp::IGNORECASE : 0)
    rexes = args.map{|s| Regexp.new(s, rxflags)}
    # create prefix string. makes output (arguably) easier to read
    prefix = (
      if @searchboth then
        "package names and descriptions"
      elsif @opts.onlypkgname == true then
        "only package names"
      elsif @opts.onlydescript == true then
        "only descriptions"
      end
    )
    msg("Searching %s of %d packages with each of %s ... ", prefix, pkgcount, rexes.map(&:inspect).join(", "))
    if (not @opts.findpkgname.empty?) || (not @opts.finddescript.empty?) then
      pkgnames = @opts.findpkgname.map{|s| Regexp.new(s, rxflags) }
      descriptions = @opts.finddescript.map{|s| Regexp.new(s, rxflags) }
      packages.each do |pkgname, data|
        havepkgmatch = 0
        havedescmatch = 0
        sdesc = data[:sdesc]
        ldesc = data[:ldesc]
        if not descriptions.empty? then
          descriptions.each do |rx|
            if (((sdesc != nil) && sdesc.match?(rx)) || ((ldesc != nil) && ldesc.match?(rx))) then
              havedescmatch += 1
            end
          end
        end
        if not pkgnames.empty? then 
          pkgnames.each do |rx|
            if pkgname.match?(rx) then
              havepkgmatch += 1
            end
          end
        end
        if ((not pkgnames.empty?) && (havepkgmatch > 0)) && ((not descriptions.empty?) && (havedescmatch > 0)) then
          print_data(pkgname, data)
          success += 1
        end
      end
    end
    rexes.each do |rx|
      packages.each do |pkgname, data|
        if is_match(rx, pkgname, data) then
          print_data(pkgname, data)
          success =+ 1
        end
      end
    end
    msg("found: %s (searched %d packages)", ((success == 0) ? "nothing" : success.to_s), pkgcount)
  end

  def is_match(rx, pkgname, data, onlydesc: false, onlypkg: false)
    rt = false
    name = pkgname.to_s.downcase
    sdesc = data[:sdesc].downcase
    ldesc = data.fetch(:ldesc, sdesc).downcase
    #$stderr.printf("pkgname=%p, data=%p\n", name, data)
    # if neither -p nor -d specified, search both name and description
    if @searchboth then
      if (name.match?(rx) || (ldesc.match?(rx) || sdesc.match?(rx))) then
        rt = true
      end
    else
      if ((@opts.onlypkgname == true) || (onlypkg == true)) && name.match?(rx) then
        #$stderr.printf("found match for pkgname %p\n", name)
        rt = true
      elsif (@opts.onlydescript || onlydesc) && (ldesc.match?(rx) || sdesc.match?(rx)) then
        #$stderr.printf("found match for description %p | %p\n", ldesc, sdesc)
        rt = true
      end

    end
    if @opts.wantinstalled then
      rt = @installedpkgs.include?(name)
    end
    return rt
  end

  def print_data(pkgname, data)
    sdesc = data[:sdesc]
    ldesc = data.fetch(:ldesc, sdesc)
    $stdout.printf("%-40s: %s\n", pkgname, ldesc)
    $stdout.flush
  end

  def get_localconf
    if File.file?(@localconf) then
      dt = YAML.load_file(@localconf)
      #$stderr.printf("dt=\n")
      #PP.pp(dt, $stderr)
      return dt #.map{|pkgname, data| [pkgname.to_s, data]}.to_h
    else
      msg("local config %p doesn't exist! did you forget to update?", @localconf)
    end
    return {}
  end

  def get_inifiles
    all = []
    if File.file?(CYGWIN_SETUPRCFILE) then
      # get cache path from setup.rc
      cygtempdir = File.read("/etc/setup/setup.rc", 512).scan(/last-cache\n\t.*\n/).first.split(/\t/)[1].strip
      # transform path from "c:\somepath\whatever" to "c:/somepath/whatever", because
      # mixing backward and forward slashes yields invalid paths
      cygtempdir.gsub!(/\\/, "/")
      if cygtempdir && File.directory?(cygtempdir) then
        Dir.entries(cygtempdir).each do |path|
          next if ((path == ".") || (path == ".."))
          realpath = File.join(cygtempdir, path)
          all += Dir.glob(File.join(realpath, "/*/setup.ini"))
        end
      else
        msg("error: 'cygtempdir' %p is not a directory!", cygtempdir)
        exit(1)
      end
      if all.length == 0 then
        msg("error: not a single setup.ini was found! is cygtempdir (aka %p) set correctly?", cygtempdir)
        exit(1)
      end
      return all
    else
      msg("error: CYGWIN_SETUPRCFILE (aka %p) does not exist!", CYGWIN_SETUPRCFILE)
      exit(1)
    end
  end


  # this bullshit function sucks because cygwin INSISTS on
  # using a custom style ini file that is UTTERLY INCOMPATIBLE WITH EVERY CONFIG FILE
  # KNOWN TO MAN!
  # also, YES I HAVE TRIED USING YAML. IT WILL NOT PARSE AS YAML. GO AWAY.
  # it's beyond insane, and i hate it.
  def update(force = false)
    totaluniq = 0
    totalpkgs = 0
    
    @we_just_updated = true
    setupinis = get_inifiles
    # these are fields we're interested in.
    # field-inside-setupini-name => field-to-store-as-name
    inifields = {
      "sdesc" => "shortdesc",
      "ldesc" => "longdesc",
      "category" => "cat",
      "version" => "ver",
    }
    if (force == true) && File.file?(@localconf) then
      File.unlink(@localconf)
    end
    msg("will update %p now ...", @localconf)
    File.open(@localconf, "wb") do |fh|
      seen = []
      fh.puts("# DO NOT EDIT!")
      fh.puts("# this file was automatically generated by cygpackes.rb")
      fh.puts
      fh.puts(":packages:\n")
      # sure, I *could* use regular expressions. But, I can also parse it manually.
      setupinis.each do |file|
        pkgcount = 0
        # uniqcount is not actually used yet...
        uniqcount = 0
        msg(" reading from %p ...", file)
        # have to read the file in as lines, because due to cygwin's
        # funky package list syntax, lines are context sensitive
        lines = File.readlines(file)
        # iterate over data ...
        name = nil
        (0 .. lines.length).each do |idx|
          line = lines[idx]
          if line != nil then
            # package blocks are denoted with '@', i.e., '@ some-package'
            if line.start_with?("@") then
              # remove '@' and whitespace
              name = line[1, line.length].strip
              if not seen.include?(name) then
                seen.push(name)
                fidx = (idx + 1)
                isgarbageblock = false
                pkgdata = {}
                tmpdata = []
                while fidx < lines.length do
                  thisline = lines[fidx].strip
                  nextline = lines[fidx + 1]
                  # means we've reached the end of a package section
                  if (thisline.empty? && (nextline != nil)) && ((nextline[0] == '@') && (nextline[1] == ' ')) then
                    isgarbageblock = false
                    break
                    # these seem to denote special fields.
                    # they're uninteresting to us, so into the trash it goes
                  elsif ((thisline == "[prev]") || (thisline == "[test]")) then
                    isgarbageblock = true
                  else
                    if isgarbageblock == false then
                      if (not thisline.empty?) && (thisline.match(GOODFIELDS)) then
                        tmpdata.push(thisline)
                      end
                    end
                  end
                  fidx += 1
                end
                if not tmpdata.empty? then
                  pkgcount += 1
                  # the gsub gets rid of this bullshit [...] nonsense
                  # seriously, why can't cygwin just use a sane configuration???
                  tmpstr = tmpdata.join("\n")
                  pkgdata = YAML.load(tmpstr)
                  # now write!
                  fh.printf("  %s:\n", name)
                  pkgdata.each do |field, value|
                    fh.printf("    :%s: %p\n", field, value)
                  end
                  fh.printf("\n")
                end
              end
            end
          end
        end
        # show how many packages were retrieved from this file, unless
        # there were previous reads
        if totalpkgs > 0 then
          if pkgcount == 0 then
            msg("  no additional packages found")
          else
            msg("  retrieved %d additional packages", pkgcount)
            totaluniq += pkgcount
          end
        else
          msg("  retrieved %d packages", pkgcount)
          totaluniq += totalpkgs
        end
        totalpkgs += pkgcount
      end
      # write meta table (more fields to come?)
      mfields = {
        count: totalpkgs,
        lastupd: Time.now,
      }
      fh.puts(":meta:\n")
      mfields.each{|k, v|
        fh.printf("  :%s: %s\n", k.to_s, v.to_s)
      }
      # allll done, folks
      fh.puts("\n")
    end
    msg("total count: %d unique packages (%d packages; previous: %d)", totaluniq, totalpkgs, @prevpkgcount)
  end
end

begin
  opts = OpenStruct.new({
    ignorecase: true,
    onlypkgname: false,
    onlydescript: false,
    wantinstalled: false,
    findpkgname: [],
    finddescript: [],
  })
  prs = OptionParser.new{|prs|
    prs.on("-u", "--update", "update local configuration"){|_|
      opts.want_update = true
    }
    prs.on("-P", "--pkgname", "search only package names"){|_|
      opts.onlypkgname = true
    }
    prs.on("-D", "--description", "search only descriptions"){|_|
      opts.onlydescript = true
    }
    prs.on("-p<str>", "--pkgname=<str>", "search package names matching <str> (regex)"){|v|
      opts.findpkgname.push(v)
    }
    prs.on("-d<str>", "--description=<str>", "search package descriptions matching <str> (regex)"){|v|
      opts.finddescript.push(v)
    }
    prs.on("-c", "--casesensitive", "search case-sensitively (default is icase)"){|_|
      opts.ignorecase = false
    }
    prs.on("-i", "--installed", "get installed packages"){|_|
      opts.wantinstalled = true
    }
  }
  prs.parse!
  cygp = CygPackages.new(opts)
  if ARGV.empty? && (opts.findpkgname.empty? && opts.finddescript.empty?) then
    $stderr.printf("ERROR: not enough arguments\n")
    exit(1)
  else
    cygp.main(ARGV)
  end
end

