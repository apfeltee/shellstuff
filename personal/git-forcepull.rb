#!/usr/bin/ruby



begin
  thisdir = Dir.pwd
  gitdir = File.join(thisdir, ".git")
  noupd = File.join(thisdir, ".noupdate")
  branch = ARGV.shift || "master"
  if File.directory?(gitdir) then
    Dir.chdir(gitdir) do
      branches = IO.popen(["git", "branch", "--list"], "rb"){|io| io.read}.strip.split(/\n/)
      branches.each do |b|
        b.strip!
        if b[0] == '*' then
          branch = b[1 .. b.length].strip
        end
      end
    end
    if File.exist?(noupd) then
      $stderr.printf("repo contains '.noupdate', aborting!\n")
      exit(1)
    else
      $stderr.printf("using branch %p\n", branch)
      system("git", "fetch", "--all")
      system("git", "reset", "--hard", "origin/#{branch}")
    end
  else
    $stderr.printf("not a git repository: %p\n", thisdir)
    exit(1)
  end
end