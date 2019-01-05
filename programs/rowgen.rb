#!/usr/bin/ruby --disable-gems

require "ostruct"
require "optparse"

class ValueGenerator
  def initialize(opts, spec)
    @rowvalue = opts.rowval
    @rownummin = opts.rownummin
    @rownummax = opts.rownummax
    @format = opts.numformat
    if spec == nil then
      @callme = "refl_get_randnum"
    else
      @callme = "refl_get_value"
    end
  end

  def refl_get_randnum
    n = Random.new.rand(@rownummin .. @rownummax) 
    if @format != nil then
      return sprintf(@format, n)
    end
    return n
  end

  def refl_get_value
    return @rowvalue
  end

  def get
    return self.send(@callme)
  end
end

class RowGenerator
  def initialize(opts)
    @opts = opts
  end

  def gen(ioto)
    idx = 0
    rt = 0
    # accessing OpenStruct directly is actually kinda slow
    rowamount = @opts.rowamount
    colamount = @opts.colamount
    rowterm = @opts.rowterm
    colterm = @opts.colterm
    valgen = ValueGenerator.new(@opts, @opts.rowval)
    while true do
      (0 ... rowamount).each do |rid|
        rt += ioto.write(valgen.get.to_s)
        if ((rid+1) < rowamount) then
          rt += ioto.write(rowterm)
        end
      end
      rt += ioto.write(colterm)
      idx += 1
      if ((colamount > 0) && (idx == colamount)) then
        return rt
      end
    end
    return rt
  end

  def main(ioto)
    begin
      gen(ioto)
    rescue Errno::EPIPE, Interrupt => _
      return
    end
  end
end

def wantint(strv, optname, minsize: 0, maxsize: 0,  defaultval: 0)
  n = strv.to_i
  if ((minsize == -1) && (n <= minsize)) then
    return defaultval
  elsif (n > minsize) then
    return n
  else
    $stderr.printf("ERROR: %p is invalid for --%s; must be larger than %d\n", strv, optname, minsize)
    exit(1)
  end
end

begin
  opts = OpenStruct.new({
    colterm: "\n",
    rowterm: " ",
    rowval: nil, # random numbers
    rownummin: 10000,
    rownummax: 99999, # used if rowval is nil, i.e., random numbers
    numformat: nil, # optional formatting when using random numbers
    colamount: 0, # infinite
    rowamount: 3,
  })
  OptionParser.new{|prs|
    prs.on("-e<str>", "--colterm=<str>", "end-of-column terminator (default is linefeed)"){|s|
      opts.colterm = s
    }
    prs.on("-s<str>", "--rowterm=<str>", "row separator (default is space)"){|s|
      opts.rowterm = s
    }
    prs.on("-v<str>", "--rowvalue=<str>", "value for rows (default are random numbers)"){|v|
      opts.rowval = v
    }
    prs.on("-n<num>", "--minnum=<num>", "minimum value for random numbers"){|v|
      opts.rownummin = wantint(v, "minnum", minsize: 0)
    }
    prs.on("-m<num>", "--maxnum=<num>", "maximum value for random numbers"){|v|
      opts.rownummax = wantint(v, "maxnum", minsze: 0)
    }
    prs.on("-c<n>", "--colamount=<n>", "amount of columns (default is infinite)"){|v|
      opts.colamount = wantint(v, "colamount", minsize: -1, defaultval: 0)
    }
    prs.on("-r<n>", "--rowamount=<n>", "amount of rows (default is 3)"){|v|
      opts.rowamount = wantint(v, "rowamount")
    }
  }.parse!
  $stdout.sync = true
  RowGenerator.new(opts).main($stdout)
end
