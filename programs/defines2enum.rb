#!/usr/bin/ruby

begin
  if $stdin.tty? && (ARGV[0] != "-") then
    $stderr.printf("pipe a chunk of #defines to get an enum-formatted list (use '-' to read stdin anyway)\n")
    exit(1)
  else
    begin
      $stdin.each_line do |line|
        line.strip!
        next if line.empty?
        m = line.match(/^\s*#\s*define\s*(?<ident>\w+)\s+(?<value>.*)/)
        if m == nil then
          $stderr.printf("warning: failed to parse %p\n", line)
          puts(line)
        else
          printf("%s = %s,\n", m["ident"].strip, m["value"].strip)
        end
      end
    rescue Interrupt
    end
  end
end

