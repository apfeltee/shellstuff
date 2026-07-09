#!/usr/bin/ruby

JAVA_CMD = [
  "java",
  # additional options for java.exe can be passed past this line!
  # make sure to put them in quotes, i.e.: "-XSomeOption=1"
]

# absolute path to your cfr.jar 
CFR_JAR = "/cygdrive/c/cloud/gdrive/portable/devtools/decompilers/java/cfr.jar"

def get_cfr_jar
  if ENV["WSL_DISTRO_NAME"] != nil then
    return CFR_JAR.gsub(/^\/cygdrive\//, "/mnt/")
  else
    cyg = IO.popen(["cygpath", "-ma", CFR_JAR], "rb"){|io| io.read }
    return cyg.strip
  end
end
### no need to edit below (unless you want to, obviously) ###

begin
  cfr = get_cfr_jar()
  if not File.file?(cfr) then
    $stderr.printf("cfr jar file %p does not exist or is not readable\n", cfr)
    exit(1)
  end
  exec(*JAVA_CMD, "-jar", cfr, *ARGV)
end