#!/usr/bin/python2

'''
NAME

   uniso

SYNOPSIS

   extract file hierarchies from an iso image

DESCRIPTION

   uniso takes data in the same format as the output of 'isoinfo -l', and
   extracts the hierarchy to the current directory.
   
   If the -R option to isoinfo is used, hard links and symbolic links will be
   faithfully reproduced.

   Does not currently adjust file ownership.

EXAMPLE

   isoinfo -l -R -i myfile.iso -l | uniso -R -i myfile.iso
   isoinfo -l -J -R -i myfile.iso | uniso -R -i myfile.iso

REQUIREMENTS

   isoinfo

      http://cdrecord.berlios.de/old/private/cdrecord.html

   chmod
   gnu ln
   touch


TO DO

   Empty


COPYRIGHT

   Copyright 2007, Nathan Coulter, uniso@pooryorick.com

LICENSE

   Licensed under the same Same terms as the PYTHON SOFTWARE FOUNDATION
   LICENSE VERSION 2 
   
   http://www.python.org/download/releases/2.5.1/license/
   
   with terms redefined as follows:
   
      PSF: the copyright holder of this
      Python: this work
'''
from __future__ import generators 

import os
import re
import sys


#DEBUG=1
DEBUG=0

try:
	from pythoric.pipeline import pipeline, read, close
	from pythoric.pipeline import open as open_
except:
	#embed pythoric.pipeline
	import os
	import signal
	import sys

	class PipelineError(Exception):
		pass

	def pipeline(*cmds):
		pids = []
		readinit = read = sys.stdin.fileno()
		for cmd in cmds:
			read1, write1 = os.pipe()
			pid = os.fork()
			if not pid:
				os.dup2(read, 0)
				os.dup2(write1, 1)
				os.close(write1)
				try:
					os.execvp(cmd[0], cmd[1:])
				except:
					cls, inst = sys.exc_info()[:2]
					inst.args = (inst.args[0], '%s:  %s' % (inst.args[1], ' '.join(cmd)))
					raise (cls(inst), inst.args)
			pids.append(pid)
			if read != readinit:
				os.close(read)
			os.close(write1)
			read = read1 
		return read1, pids

	def open_(*cmds):
		if getattr(cmds[0], 'read', None):
			read, write = os.pipe()
			sys.stdin = os.fdopen(read)
			pid = os.fork()
			if not pid:
				sys.stdin.close()
				while 1:
					data = cmds[0].read(512)
					if not data: break
					os.write(write, data)
					os._exit(0)
			else:
				os.close(write)
				stdout, pids = pipeline(*cmds[1:])
		else:
			stdout, pids = pipeline(*cmds)
		return os.fdopen(stdout), pids

	def read(*cmds):
		file_, pids = open_(*cmds)
		out = file_.read()
		s = close(pids)
		if max(s) > 0:
			raise PipelineError("return status:  %s" % s) 
		return out

	def close(pids):
		for pid in pids:
			try:
				os.kill(pid, signal.SIGTERM)
				os.kill(pid, signal.SIGKILL)
			except OSError:
				pass
		return map(lambda x: os.WEXITSTATUS(os.waitpid(x,0)[1]), pids)


WARNING_RR_MOVED = '''
Warning:  this image contains deep directories which have been relocated
to /rr_moved.  uniso currently lacks the ability to reconstruct the
original location of these directories, and they will remain in /rr_moved.
'''
def usage():
	print(__doc__)
	 

class unisoError(RuntimeError):
	pass

def fields(record):
	out = []
	record = record.lstrip()
	record = record.split(' ')
	#some versions of isoinfo include an 'inode' field at position 0
	if not record[0].startswith('-d') and not record[0].startswith('-'):
		record.pop(0)
	#spaces in filenames preclude simply removing spaces between fields
	while 1:
		next = record.pop(0)
		if next == '[':
			break
		if next: out.append(next)
	# there is no space between uid and gid
	if len(out) < 8 : out.insert(3, '')
	while len(out) < 10:
		next = record.pop(0)
		if next: out.append(next)
	out[-1] = out[-1][0:-1]
	while not record[0]:  record.pop(0)
	try:
		idx = record.index('->')
	except ValueError:
		idx = -1
	if idx > -1 and not int(out[4]):
		out.extend((
			' '.join(record[:idx]),
			' '.join(record[idx+1:])
		))
	else:
		out.extend(('', ' '.join(record)))

	return out

def records (isoinfo):
	'''
	value: and iterator yielding a list:
		[ directory, permissions, refcount, user, group, other, year,]

	The inode of the next record is inspected to determine if an record
	is a symbolic link


	'''
	dirmark = re.compile("Directory listing of ")
	for record in isoinfo:
		record = record.rstrip(' 	\n')
		if not record:
			continue
		newdir = re.match(dirmark, record)
		if newdir:
			dir = record[newdir.end():]
			continue
		out = [dir]
		out.extend(fields(record))
		if DEBUG:
			print >> sys.stderr, '\nrecords function will yield:  ', out
		yield out

def main ():
	if len(sys.argv) < 2:
		usage()
		sys.exit(1)
	pwd = os.getcwd()
	image = sys.argv[1]
	isoinfo = [ 'isoinfo', 'isoinfo']
	isoinfo.extend(sys.argv[1:])
	hardlinks = {}
	for record in records(sys.stdin):
		if record[12] == '.' or record[12] == '..':
			continue
		if DEBUG:  print >> sys.stderr,  'Current Record: %s' % record
		where = pwd
		field0 = record[0]
		if field0:
			where = os.path.join(where, field0.lstrip(os.path.sep))
			if DEBUG: print >> sys.stderr, 'Filesystem Path:  %s' % where
		if field0 == '/' and record[10] == '02' and record[12] == 'rr_moved':
			print >> sys.stderr, WARNING_RR_MOVED
		if not os.path.isdir(where):
			os.makedirs(where)
		what = os.path.join(where, record[12])
		if record[10] == '02':
			os.makedirs(what)
		elif record[10] == '00':
			assert(record[12])
			if record[11]:
				link = os.path.join(where, record[11])
				cmd = ('ln', 'ln', '-sf', record[12], link)
				read(cmd)
			else:
				link = hardlinks.get(record[9], None)
				if link:
					cmd = ('ln', 'ln', link, what)
					read(cmd)
				else:
					imagePath = record[0] + record[12]
					fhout = open(what,'wb')
					cmd = isoinfo + ['-x', imagePath]
					contents, pids = open_(cmd)
					for out in contents:
						fhout.write(bytes(out))
					fhout.close()
					contents.close()
					close(pids)

				if int(record[2]) > 1:
					if not hardlinks.has_key(record[9]):
						hardlinks[record[9]] = what

				if DEBUG:  print >> sys.stderr, 'permissions:  ', record[1][1:4]
				assert(os.path.exists(what))

				chmod = ('chmod', 'chmod',
					'u=' + record[1][1:4].replace('-','') +
					',g=' + record[1][4:7].replace('-','') +
					',o=' + record[1][8:11].replace('-',''),
					what
				)
				read(chmod)

			if DEBUG: print >> sys.stderr, '\ntime:  ', ' '.join(record[6:9])
			touch = ('touch', 'touch', '-d', ' '.join(record[6:9]), what)
			read(touch)


if __name__ == '__main__':
	main()
