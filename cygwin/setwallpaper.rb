#!/usr/bin/ruby

require "ffi"
require "shellwords"
require "~/dev/gems/lib/cygpath.rb"


module Win32
  extend FFI::Library

  ffi_lib "wininet.dll"
  attach_function :InternetGetConnectedState, [:long,:long], :long

  ffi_lib "user32.dll"
  attach_function :SystemParametersInfoA, [:int, :int, :string, :int], :int
end


def vsystem(*cmd)
  $stderr.printf("running: %s\n", cmd.shelljoin)
  if not (rc=system(*cmd)) then
    $stderr.printf(" ... seems to have failed!\n")
  end
  return rc
end

def reg(cmd, *vargs)
  regexe = "c:/windows/system32/reg.exe"
  shcmd = [regexe, cmd, *vargs].map(&:to_s)
  return vsystem(*shcmd)
end

def rundll32(dll, fn, *rest)
  #startexe = "c:/windows/system32/start.exe"
  cmdexe = "c:/windows/system32/cmd.exe"
  rdexe = "c:/windows/system32/rundll32.exe"
  shcmd = [cmdexe, "/c", "start", "", "/b", rdexe, sprintf("%s,%s", dll, fn), *rest].map(&:to_s)
  #shcmd = [cmdexe, "/c", "start", "", "/b", rdexe, [dll, fn, *rest].join(", ")].map(&:to_s)
  return vsystem(*shcmd)
end


=begin
  case Style.Stretch:
    key.SetValue(@"WallpaperStyle", "2");
    key.SetValue(@"TileWallpaper", "0");
    break;
  case Style.Center:
    key.SetValue(@"WallpaperStyle", "1");
    key.SetValue(@"TileWallpaper", "0");
    break;
  case Style.Tile:
    key.SetValue(@"WallpaperStyle", "1");
    key.SetValue(@"TileWallpaper", "1");
    break;
=end

def setwallpaper(file)
  consts = {
    SetDesktopWallpaper: 20,
    UpdateIniFile: 0x01,
    SendWinIniChange: 0x02,
  }
  rkey = "HKEY_CURRENT_USER\\control panel\\desktop"
  winpath = Cygpath.cyg2win(file)
  Win32.SystemParametersInfoA(consts[:SetDesktopWallpaper], 0, winpath, consts[:UpdateIniFile] | consts[:SendWinIniChange]);
  reg("add", rkey, "/v", "WallpaperStyle", "/t", "REG_SZ", "/d", 2, "/f")
  $stderr.printf("successfully set %p as wallpaper\n", winpath)
end


begin
  file = ARGV.shift
  if file.nil? then
    $stderr.printf("usage: setwallpaper <imagefile>\n")
    exit(1)
  else
    if File.file?(file) then
      if file.match(/\.(jpe?g|png|gif)/i) then
        setwallpaper(file)
      else
        $stderr.printf("error: extension of %p is unrecognized\n", file)
      end
    else
      $stderr.printf("error: not a file: %p\n", file)
    end
  end
end
