#!/usr/bin/ruby

require "ostruct"
require "optparse"
require "json"


def work(opts, name, hnd)
  begin
    data = JSON.load(hnd)
    if opts.checkonly then
      if not opts.noprint then
        print(JSON.dump(data))
      end
      return 0
    elsif opts.prettyprint then
      if opts.useap then
        require "awesome_print"
        ap data
      else
        print(JSON.pretty_generate(data))
      end
      return 0
    end
  rescue => ex
    emsg = ex.message
    # if a document is reaqlly b0rked, json might accidentally
    # dump the entire document in the exception message...
    if emsg.length > 50 then
      emsg = emsg[0 .. 50]
    end
    $stderr.printf("%s: parsing json failed: (%s) %s\n", $0, ex.class.name, emsg)
    return 1
  end
  return 0
end


begin
  $0 = File.basename($0)
  opts = OpenStruct.new({
    checkonly: false,
    noprint: false,
    prettyprint: true,
  })
  OptionParser.new{|prs|
    prs.on("-h", "--help", "show this help and exit"){
      puts(prs.help)
      exit(0)
    }
    prs.on("-r", "--parse-only", "parse and print as-is (syntax check)"){
      opts.checkonly = true
      opts.prettyprint = false
    }
    prs.on("-n", "--no-print", "do not print anything"){
      opts.noprint = true
    }
    prs.on("-p", "--prettyprint", "prettyprint the json dump (default)"){
      opts.prettyprint = true
    }
    prs.on("-a", "--awesomeprint", "use the awesome_print gem to print"){
      opts.prettyprint = true
      opts.useap = true
    }
  }.parse!
  if ARGV.empty? then
    if $stdin.tty? then
      $stderr.printf("no files proved, and nothing piped! try %p --help\n", $0)
      exit(1)
    else
      exit(work(opts, "<stdin>", $stdin) ? 0 : 1)
    end
  else
    # cummulative error code(s) stored here
    crt = 0
    ARGV.each do |arg|
      begin
        File.open(arg, "rb") do |fh|
          crt += (work(opts, arg, fh) ? 0 : 1)
        end
      rescue => ex
        $stderr.printf("%s: failed to open %p for reading: (%s) %s\n", $0, arg, ex.class.name, ex.message)
        crt += 1
      end
    end
    # if crt is bigger than null, then errors occured
    exit((crt > 0) ? 1 : 0)
  end
end



