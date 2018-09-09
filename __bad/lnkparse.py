#!/usr/bin/python

# rewrite of https://github.com/HarmJ0y/pylnker to be
# arguably more pythonic. now stores values in a dict, perhaps
# going to port this to a more sensible language
#
# --- original credits below ---
# This is a quick and dirty port of lnk-parse-1.0.pl found here:
#   https://code.google.com/p/revealertoolkit/source/browse/trunk/tools/lnk-parse-1.0.pl
#   Windows LNK file parser - Jacob Cunningham - jakec76@users.sourceforge.net
#   Based on the contents of the document:
#   http://www.i2s-lab.com/Papers/The_Windows_Shortcut_File_Format.pdf
#   v1.0
#
#  Edits by YK
#   - Added support for blank/invalid timestamps
#   - Bug fixes for attribute parsing & unicode strings


import sys
import struct
import datetime
import binascii
import collections

# only used in dump()
import re

FLAG_HASH = [
    ['NO_SHELLIDLIST', 'HAS_SHELLIDLIST'],
    ['NO_FILEDIR', 'IS_FILEDIR'],
    ['NO_DESCR', 'HAS_DESCR'],
    ['NO_RELPATH', 'HAS_RELPATH'],
    ['NO_WORKDIR', 'HAS_WORKDIR'],
    ['NO_CMDLINE', 'HAS_CMDLINE'],
    ['NO_CUSTICON', 'HAS_CUSTICON']
]

FILE_HASH = [
    ['', 'READONLY'],
    ['', 'HIDDEN'],
    ['', 'SYSTEMFILE'],
    ['', 'VOLUMELABEL (not possible)'],
    ['', 'DIRECTORY'],
    ['', 'ARCHIVE'],
    ['', 'NTFS_EFS'],
    ['', 'NORMAL'],
    ['', 'TEMP'],
    ['', 'SPARSE'],
    ['', 'REPARSE_POINT_DATA'],
    ['', 'COMPRESSED'],
    ['', 'OFFLINE'],
    ['', 'NOT_CONTENT_INDEXED'],
    ['', 'ENCRYPTED']
]

#Hash of ShowWnd values
SHOW_WND_HASH = [
    'SW_HIDE',
    'SW_NORMAL',
    'SW_SHOWMINIMIZED',
    'SW_SHOWMAXIMIZED',
    'SW_SHOWNOACTIVE',
    'SW_SHOW',
    'SW_MINIMIZE',
    'SW_SHOWMINNOACTIVE',
    'SW_SHOWNA',
    'SW_RESTORE',
    'SW_SHOWDEFAULT',
]

# Hash for Volume types
VOL_TYPE_HASH = [
    'UNKNOWN',
    'NOROOTDIR',
    'REMOVABLE', # Floppy, Zip, USB, etc.
    'HARDDISK', # hard disks
    'REMOTE', # network drives
    'CDROM',
    'RAMDRIVE',
]

def reverse_hex(HEXDATE):
    #sys.stderr.write("reverse_hex(%s)\n" % repr(HEXDATE))
    hexVals = [HEXDATE[i:i + 2] for i in xrange(0, 16, 2)]
    reversedHexVals = hexVals[::-1]
    return ''.join(reversedHexVals)


def assert_lnk_signature(f):
    f.seek(0)
    sig = f.read(4)
    guid = f.read(16)
    if sig != 'L\x00\x00\x00':
        raise Exception("This is not a .lnk file.")
    if guid != '\x01\x14\x02\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00F':
        raise Exception("Cannot read this kind of .lnk file.")


# read COUNT bytes at LOC and unpack into binary
def read_unpack_bin(f, loc, count):
    # jump to the specified location
    #sys.stderr.write("read_unpack_bin(f=%s, loc=%s, count=%s)\n" % (repr(f), repr(loc), repr(count)))
    f.seek(loc)
    raw = f.read(count)
    result = ""
    for b in raw:
        result += ("{0:08b}".format(ord(b)))[::-1]
    return result


# read COUNT bytes at LOC and unpack into ascii
def read_unpack_ascii(f,loc,count):
    # jump to the specified location
    f.seek(loc)
    # should interpret as ascii automagically
    return f.read(count)


# read COUNT bytes at LOC
def read_unpack(f, loc, count):
    # jump to the specified location
    f.seek(loc)
    raw = f.read(count)
    result = ""
    for b in raw:
        result += binascii.hexlify(b)
    return result


# Read a null terminated string from the specified location.
def read_null_term(f, loc):
    # jump to the start position
    f.seek(loc)
    result = ""
    b = f.read(1)
    #while b != "\x00":
    while True:
        result += str(b)
        b = f.read(1)
        if b is None:
            break
        if b == '':
            return result
        #if ord(b) == 0:
        if str(b) == "\0":
            #sys.stderr.write("found nulbyte, returning %s\n" % repr(result))
            return result
    return result


# adapted from pylink.py
def ms_time_to_unix_str(windows_time):
    time_str = ''
    try:
        unix_time = windows_time / 10000000.0 - 11644473600
        time_str = str(datetime.datetime.fromtimestamp(unix_time))
    except:
        pass
    return time_str

def add_info(f,loc):
    tmp_len_hex = reverse_hex(read_unpack(f,loc,2))
    # a wild guess
    tmp_len = 16
    if len(tmp_len_hex) > 0:
        tmp_len = 2 * int(tmp_len_hex, 16)
        #sys.stderr.write("add_info: tmp_len=%d (tmp_len_hex=%s)\n" % (tmp_len, repr(tmp_len_hex)))
    loc += 2
    if (tmp_len != 0):
        tmp_string = read_unpack_ascii(f, loc, tmp_len)
        now_loc = f.tell()
        return (tmp_string, now_loc)
    else:
        now_loc = f.tell()
        return (None, now_loc)


def dump(obj):
    tmp = repr(obj)
    tmp = tmp.replace('"', "\\" + '"')
    tmp = re.sub(r"^u'", "'", tmp)
    tmp = re.sub(r"^'",  '"', tmp)
    tmp = re.sub(r"'$",  '"', tmp)
    
    return tmp

def maybenull(obj):
    if isinstance(obj, basestring):
        if len(obj) == 0:
            return None
    return obj

def filt_nonascii(ch):
    bt = ord(ch)
    return ((ch == '\n') or ((bt >= 32) and (bt <= 126)))

def fixstr(s):
    if s is None:
        return None
    try:
        #return maybenull(unicode(s, "utf-16"))
        raise
    except:# UnicodeDecodeError as e:
        #tmp = unicode(s, "ascii", "ignore")
        tmp = s.encode("ascii", errors="ignore") #.decode()
        # \x04 apparently means space?
        #tmp = tmp.replace("\x04", " ")
        # this happens far too often to be coincidental ...
        tmp = re.sub(r"[\x01-\x0F]", " ", tmp)
        # finally, get rid of stray nuls.
        # seems that VEEEEERY old lnk files used nulbytes to pad strings,
        # kind of like ancient pascal/fortran. might be a DOS thing, though.
        #tmp = tmp.replace("\0", "")
        #tmp = re.sub(r'[^\x00-\x7f]', '', tmp) 
        tmp = filter(filt_nonascii, tmp)
        # could still be empty!
        return maybenull(tmp.strip())

def parse_lnk(filename):
    table = {}
    #read the file in binary mode
    with open(filename, 'rb') as f:
        try:
            assert_lnk_signature(f)
        except Exception as e:
            print("[!] Exception: "+str(e))
            return None
        table["lnkfile"] = filename

        # get the flag bits
        flags = read_unpack_bin(f,20,1)
        flag_desc = list()

        # flags are only the first 7 bits
        for cnt in xrange(len(flags)-1):
            bit = int(flags[cnt])
            # grab the description for this bit
            flag_desc.append(FLAG_HASH[cnt][bit])

        table["flags"] = " | ".join(flag_desc)

        # File Attributes 4bytes@18h = 24d
        file_attrib = read_unpack_bin(f,24,4)
        attrib_desc = list()
        for cnt in xrange(0, 14):
            bit = int(file_attrib[cnt])
            # grab the description for this bit
            if bit == 1:
                attrib_desc.append(FILE_HASH[cnt][1])
        if len(attrib_desc) > 0:
            table["attribs"] = ' | '.join(attrib_desc)

        # Create time 8bytes @ 1ch = 28
        create_time = reverse_hex(read_unpack(f,28,8))
        untm = ms_time_to_unix_str(int(create_time, 16))
        table["tm_created"] = untm

        # Access time 8 bytes@ 0x24 = 36D
        access_time = reverse_hex(read_unpack(f,36,8))
        untm = ms_time_to_unix_str(int(access_time, 16))
        table["tm_access"] = untm

        # Modified Time8b @ 0x2C = 44D
        modified_time = reverse_hex(read_unpack(f,44,8))
        untm = ms_time_to_unix_str(int(modified_time, 16))
        table["tm_modified"] = untm

        # Target File length starts @ 34h = 52d
        length_hex = reverse_hex(read_unpack(f,52,4))
        length = int(length_hex, 16)
        table["target_length"] = length

        # Icon File info starts @ 38h = 56d
        icon_index_hex = reverse_hex(read_unpack(f,56,4))
        icon_index = int(icon_index_hex, 16)
        if icon_index != 0:
            table["icon_index"] = icon_index

        # show windows starts @3Ch = 60d 
        show_wnd_hex = reverse_hex(read_unpack(f,60,1))
        show_wnd = int(show_wnd_hex, 16)
        table["showwnd"] = SHOW_WND_HASH[show_wnd]

        # hot key starts @40h = 64d 
        hotkey_hex = reverse_hex(read_unpack(f,64,4))
        hotkey = int(hotkey_hex, 16)
        if hotkey != 0:
            table["hotkey"] = hotkey

        #------------------------------------------------------------------------
        # End of Flag parsing
        #------------------------------------------------------------------------

        # get the number of items
        items_hex = reverse_hex(read_unpack(f,76,2))
        items = int(items_hex, 16)

        list_end = 78 + items

        struct_start = list_end
        first_off_off = struct_start + 4
        vol_flags_off = struct_start + 8
        local_vol_off = struct_start + 12
        base_path_off = struct_start + 16
        net_vol_off = struct_start + 20
        rem_path_off = struct_start + 24

        # Structure length
        struct_len_hex = reverse_hex(read_unpack(f,struct_start,4))
        struct_len = 8
        if len(struct_len_hex) > 0:
            struct_len = int(struct_len_hex, 16)
        struct_end = struct_start + struct_len

        # First offset after struct - Should be 1C under normal circumstances
        first_off = read_unpack(f,first_off_off,1)

        # File location flags
        vol_flags = read_unpack_bin(f,vol_flags_off,1)
        vol_code = vol_flags[:2]

        # Local volume table
        # Random garbage if bit0 is clear in volume flags
        if (vol_code == "10") or (vol_code == ""):
            
            table["target_type"] = "local"

            # This is the offset of the local volume table within the 
            # File Info Location Structure
            loc_vol_tab_off_hex = reverse_hex(read_unpack(f,local_vol_off,4))
            loc_vol_tab_off = 0
            if len(loc_vol_tab_off_hex) > 0:
                loc_vol_tab_off = int(loc_vol_tab_off_hex, 16)

            # This is the asolute start location of the local volume table
            loc_vol_tab_start = loc_vol_tab_off + struct_start

            # This is the length of the local volume table
            local_vol_len_hex = reverse_hex(read_unpack(f,loc_vol_tab_off+struct_start,4))
            local_vol_len = 0
            if len(local_vol_len_hex) > 0:
                local_vol_len = int(local_vol_len_hex, 16)

            # We now have enough info to
            # Calculate the end of the local volume table.
            local_vol_tab_end = loc_vol_tab_start + local_vol_len

            # This is the volume type
            curr_tab_offset = loc_vol_tab_off + struct_start + 4
            vol_type_hex = reverse_hex(read_unpack(f,curr_tab_offset,4))
            vol_type = 0
            if len(vol_type_hex) > 0:
                vol_type = int(vol_type_hex, 16)
            table["target_voltype"] = VOL_TYPE_HASH[vol_type]

            # Volume Serial Number
            curr_tab_offset = loc_vol_tab_off + struct_start + 8
            vol_serial = reverse_hex(read_unpack(f,curr_tab_offset,4))
            table["target_volserial"] = vol_serial

            # Get the location, and length of the volume label 
            vol_label_loc = loc_vol_tab_off + struct_start + 16
            vol_label_len = local_vol_tab_end - vol_label_loc
            vol_label = read_unpack_ascii(f,vol_label_loc,vol_label_len);
            table["target_vollabel"] = fixstr(vol_label)

            #------------------------------------------------------------------------
            # This is the offset of the base path info within the
            # File Info structure
            #------------------------------------------------------------------------

            base_path_off = 0 # ???
            base_path_off_hex = reverse_hex(read_unpack(f,base_path_off,4))
            if len(base_path_off_hex) > 0:
                base_path_off = struct_start + int(base_path_off_hex, 16)

            # Read base path data upto NULL term 
            base_path = read_null_term(f,base_path_off)
            table["target_basepath"] = fixstr(base_path)

        # Network Volume Table
        elif vol_code == "01":

            # TODO: test this section!
            table["target_type"] = "netshare"

            net_vol_off_hex = reverse_hex(read_unpack(f,net_vol_off,4))
            net_vol_off = struct_start + int(net_vol_off_hex, 16)
            net_vol_len_hex = reverse_hex(read_unpack(f,net_vol_off,4))
            net_vol_len = struct_start + int(net_vol_len_hex, 16)

            # Network Share Name
            net_share_name_off = net_vol_off + 8
            net_share_name_loc_hex = reverse_hex(read_unpack(f,net_share_name_off,4))
            net_share_name_loc = int(net_share_name_loc_hex, 16)

            if(net_share_name_loc != 20):
                print(" [!] Error: NSN ofset should always be 14h\n")
                sys.exit(1)

            net_share_name_loc = net_vol_off + net_share_name_loc
            net_share_name = read_null_term(f,net_share_name_loc)
            table["target_sharename"] = fixstr(net_share_name)

            # Mapped Network Drive Info
            net_share_mdrive = net_vol_off + 12
            net_share_mdrive_hex = reverse_hex(read_unpack(f,net_share_mdrive,4))
            net_share_mdrive = int(net_share_mdrive_hex, 16)

            if(net_share_mdrive != 0):
                net_share_mdrive = net_vol_off + net_share_mdrive
                net_share_mdrive = read_null_term(f,net_share_mdrive)
                table["target_mapdrive"] = fixstr(net_share_mdrive)

        else:
            sys.stderr.write(" [!] Error: unknown volume flags (flag string = %s)\n" % repr(vol_flags))
            sys.exit(1)


        # Remaining path
        try:
            rem_path_off_hex = reverse_hex(read_unpack(f,rem_path_off,4))
            rem_path_off = struct_start +int(rem_path_off_hex, 16)
            rem_data = read_null_term(f,rem_path_off);
            table["target_apprem"] = fixstr(rem_data)
        except:
            pass
        #------------------------------------------------------------------------
        # End of FileInfo Structure
        #------------------------------------------------------------------------

        # The next starting location is the end of the structure
        next_loc = struct_end
        addnl_text = ""
        if flags[2] == "1":
            addnl_text, next_loc = add_info(f,next_loc)
            #sys.stderr.write("meta_description: addnl_text=%s, next_loc=%s\n" % (repr(addnl_text), repr(next_loc)))
            v = fixstr(addnl_text)
            # i *think* descriptions need additional parsing.
            # i might be wrong.
            table["meta_description"] = v
                
        if flags[3]=="1":
            addnl_text, next_loc = add_info(f,next_loc)
            v = fixstr(addnl_text)
            table["target_relpath"] = v
            

        if flags[4]=="1":
            addnl_text, next_loc = add_info(f,next_loc)
            v = fixstr(addnl_text)
            table["target_workingdir"] = v
            

        if flags[5]=="1":
            addnl_text,next_loc = add_info(f,next_loc)
            v = fixstr(addnl_text)
            table["target_cmdline"] = v
            

        if flags[6]=="1":
            addnl_text,next_loc = add_info(f,next_loc)
            v = fixstr(addnl_text)
            table["meta_icon"] = v

    return table


def usage():
    print "usage: lnkparse <file.lnk> [<file2.lnk> <fileN.lnk> ...]"
    sys.exit(1)



if __name__ == "__main__":
    if len(sys.argv) == 1:
        usage()
    else:
        fargs = sys.argv[1:]
        flen = len(fargs)
        sys.stdout.write("[\n")
        for fidx, arg in enumerate(fargs):
            sys.stderr.write("** file: %s\n" % repr(arg))
            darg = dump(arg)
            sys.stdout.write("  {\n")
            tab = parse_lnk(arg)
            tlen = len(tab)
            if tab:
                od = sorted(tab)
                for idx, name in enumerate(od):
                    val = tab[name]
                    if val is not None:
                        fmtkey = dump(name) + ":"
                        fmtval = dump(val)
                        sys.stdout.write("%20s %s" % (fmtkey, fmtval))
                        if (idx+1) < tlen:
                            sys.stdout.write(",")
                        sys.stdout.write("\n")
            sys.stdout.write("  }")
            if ((fidx + 1) < flen):
                sys.stdout.write(",")
            sys.stdout.write("\n")
        sys.stdout.write("]\n")

#eof
