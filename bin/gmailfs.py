#!/usr/bin/python
#@+leo-ver=4
#@+node:@file gmailfs.py
#@@first
#
#    Copyright (C) 2004  Richard Jones  <richard followed by funny at sign then jones then a dot then name>
#    Copyright (C) 2010  Dave Hansen <dave@sr71.net>
#
#    GmailFS - Gmail Filesystem Version 0.8.6
#    This program can be distributed under the terms of the GNU GPL.
#    See the file COPYING.
#
# TODO:
# Problem: a simple write ends up costing at least 3 server writes:
# 	1. create directory entry
# 	2. create inode
# 	3. create first data block
# It would be greate if files below a certain size (say 64k or something)
# could be inlined and just stuck as an attachment inside the inode.
# It should not be too big or else it will end up making things like
# stat() or getattr() much more expensive
#
# It would also be nice to be able to defer actual inode creation for
# a time.  dirents are going to be harder because we look them up more,
# but inodes should be easier to keep consistent
#
# Wrap all of the imap access functions up better so that we
# can catch the places to invalidate the caches better.
#
# Are there any other options for storing messages than in base64-encoded
# attachments?  I'm worried about the waste of space and bandwidth.  It
# appears to be about a 30% penalty.
#
# Be more selective about clearing the rsp cache.  It is a bit heavy-handed
# right now.  Do we really even need the rsp cache that much?  We do our own
# caching for blocks and inodes.  I guess it helps for constructing readdir
# responses.
#
# CATENATE
# See if anybody supports this: http://www.faqs.org/rfcs/rfc4469.html
# It would be wonderful when only writing parts of small files, or even
# when updating inodes.
#
# MUTIAPPEND
# With this: http://www.faqs.org/rfcs/rfc3502.html
# we could keep track of modified inodes and submit them in batches back
# to the server
#
# Could support "mount -o ro" or "mount -o remount,ro" with a read-only
# selection of the target mailbox
#
# There some tangling up here of inodes only having a single path
#

"""
GmailFS provides a filesystem using a Google Gmail account as its storage medium
"""

#@+others
#@+node:imports

import pprint

try:
	import fuse
except ImportError, e:
	print e
	print "Are you sure you sure fuse is built into the kernel or loaded as a module?"
	print "In a linux shell type \"lsmod | grep fuse\" to find out."

import imaplib
import email
import random
from email import encoders
from email.mime.multipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.mime.base import MIMEBase


import Queue
from fuse import Fuse
import os
from threading import Thread
import threading
import thread
from errno import * # NOTE: wildcard star imports considered evil, namespace pollution
from stat import *
from os.path import abspath, expanduser, isfile

fuse.fuse_python_api = (0, 2)


import thread
import quopri

import sys,traceback,re,string,time,tempfile,array,logging,logging.handlers

#@-node:imports

# Globals
DefaultUsername = 'defaultUser'
DefaultPassword = 'defaultPassword'
DefaultFsname = 'gmailfs'
References={}

IMAPBlockSize = 1024

# this isn't used yet
InlineInodeMax = 32 * 1024

# I tried 64MB for this, but the base64-encoded
# blocks end up about 90MB per message, which is
# a bit too much, and gmail rejects them.
DefaultBlockSize = 512 * 1024

# How many blocks can we cache at once
BlockCacheSize = 100

SystemConfigFile = "/etc/gmailfs/gmailfs.conf"
UserConfigFile = abspath(expanduser("~/.gmailfs.conf"))

GMAILFS_VERSION = '5'
PATHNAME_MAX = 256

DELETE_AFTER_READ = 1
KEEP_AFTER_READ = 0

PathStartDelim  = '__a__'
PathEndDelim    = '__b__'
FileStartDelim  = '__c__'
FileEndDelim    = '__d__'
LinkStartDelim  = '__e__'
LinkEndDelim    = '__f__'
MagicStartDelim = '__g__'
MagicEndDelim   = '__h__'
InodeSubjectPrefix = 'inode_msg'
DirentSubjectPrefix = 'dirent_msg'

InodeTag ='i'
DevTag = 'd'
NumberLinksTag = 'k'
FsNameTag = 'q'
ModeTag = 'e'
UidTag = 'u'
GidTag = 'g'
SizeTag = 's'
AtimeTag = 'a'
MtimeTag = 'm'
CtimeTag = 'c'
BSizeTag = 'z'
VersionTag = 'v'
SymlinkTag = 'l'

RefInodeTag = 'r'
FileNameTag = 'n'
PathNameTag = 'p'

NumberQueryRetries = 1

regexObjectTrailingMB = re.compile(r'\s?MB$')

rsp_cache_hits = 0
rsp_cache_misses = 0
rsp_cache = {}

debug = 1
if "DEBUG" in os.environ:
	debug = int(os.environ['DEBUG'])
if debug >= 3:
	imaplib.Debug = 3
#imaplib.Debug = 4

writeout_threads = {}
def abort():
	global do_writeout
	do_writeout = 0
	#for t in writeout_threads:
	#	print "abort joining thread..."
	#	t.join()
	#	print "done joining thread"
	exit(0)

sem_msg = {}

def semget(sem):
	tries = 0
	while not sem.acquire(0):
		tries = tries + 1
		time.sleep(1)
		if tries % 60 == 0:
			print("[%d] hung on lock for %d seconds (holder: %s)" % (thread.get_ident(), tries, sem_msg[sem]))
			traceback.print_stack()
	if tries >= 60:
		print("[%d] unhung on lock after %d seconds (last holder: %s)" % (thread.get_ident(), tries, sem_msg[sem]))
	sem_msg[sem] = "acquired semget"
	return "OK"

def log_error(str):
	log.debug(str)
	log.error(str)
	sys.stdout.write(str+"\n")
	sys.stderr.write(str+"\n")
	return

def log_debug(str):
	log_debug3(str)
	#str += "\n"
	#sys.stderr.write(str)
	return

def log_entry(str):
	#print str
	log_debug1(str)

def am_lead_thread():
	if writeout_threads.has_key(thread.get_ident()):
		return 0
	return 1

def log_debug1(str):
	log_info(str)
	#str += "\n"
	#sys.stderr.write(str)
	return

def log_debug2(str):
	if debug >= 2:
		log_info(str)
	return

def log_debug3(str):
	if debug >= 3:
		log_info(str)
	return

def log_debug4(str):
	if debug >= 4:
		log_info(str)
	return

def log_imap(str):
	log_debug2("IMAP: " + str)

def log_imap2(str):
	log_debug3("IMAP: " + str)

def log_info(s):
	if not am_lead_thread():
		return
	log.info("[%.2f] %s" % (time.time(), s))
	#print str
	#str += "\n"
	#sys.stderr.write(str)
	return

def log_warning(str):
	log.warning(str)
	#str += "\n"
	#sys.stderr.write(str)
	return

def parse_path(path):
	try:
		# rindex excepts when there's no /
		ind = string.rindex(path, '/')
		parent_dir = path[:ind]
        	filename = path[ind+1:]
	except:
		print("parse_path() exception")
		ind = 0
		parent_dir = ""
        	filename = path
	if len(parent_dir) == 0:
		parent_dir = "/"
	log_debug4("parse_path('%s') parent_dir: '%s', filename: '%s'" % (path, parent_dir, filename))
	return parent_dir, filename


def msg_add_payload(msg, payload, filename=None):
	attach_part = MIMEBase('file', 'attach')
	attach_part.set_payload(payload)
	if filename != None:
		attach_part.add_header('Content-Disposition', 'attachment; filename="%s"' % filename)
	encoders.encode_base64(attach_part)
	msg.attach(attach_part)

# This probably doesn't need to be handed the fsNameVar
# and the username
def mkmsg(subject, preamble, attach = ""):
	global username
	global fsNameVar
	msg = MIMEMultipart()
	log_debug2("mkmsg('%s', '%s', '%s', '%s',...)" % (username, fsNameVar, subject, preamble))
	msg['Subject'] = subject
	msg['To'] = username
	msg['From'] = username
	msg.preamble = preamble
	if len(attach):
		log_debug("attaching %d byte file contents" % len(attach))
		msg_add_payload(msg, attach)
	log_debug3("mkmsg() after subject: '%s'" % (msg['Subject']))
	msg.uid = -1
	return msg

imap_times = {}
imap_times_last_print = 0
def log_imap_time(cmd, start_time):
	global imap_times
	global imap_times_last_print
	if not imap_times.has_key(cmd):
		imap_times[cmd] = 0.0

	now = time.time()
	end_time = now
	duration = end_time - start_time
	imap_times[cmd] += duration
	imap_times_print()

def imap_times_print(force=0):
	global imap_times
	global imap_times_last_print
	now = time.time()
	if force or (now - imap_times_last_print > 10):
		for key, total in imap_times.items():
			log_info("imap_times[%s]: %d" % (key, total))
		imap_times_last_print = now

# this is intended to be a drop-in for imap.uid(), while
# also allowing the imap object to reconnect in the event
# of failures
#
# This hopefully just means that one of the connections
# died.  This will try to reestablish it.
def imap_uid(imap, cmd, arg1, arg2 = None, arg3 = None, arg4 = None):
	tries = 3
	ret = None
	while ret == None:
		tries = tries - 1
		try:
		        ret = imap.uid(cmd, arg1, arg2, arg3)
			if not ret == None:
				return ret;
		except Exception, e:
			log_error("imap.uid() error: %s (tries left: %d)" % (str(e), tries))
			if tries <= 0:
				abort()
		except:
			log_error("imap.uid() unknown error: (tries left: %d)" % (tries))
			if tries <= 0:
				abort()
		imap.fs.kick_imap(imap)
	return ret

def __imap_append(imap, fsNameVar, flags, now, msg):
	tries = 3
	rsp = None
	data = None
	while rsp == None:
		tries = tries - 1
		try:
		        rsp, data = imap.append(fsNameVar, flags, now, msg)
			log_debug2("__imap_append() try: %d rsp: '%s'" % (tries, rsp))
			if rsp == "NO":
				time.sleep(1)
				rsp = None
				continue
		except:
			log_error("imap.append() exception: '%s' (tries left: %d)" % (sys.exc_info()[0], tries))
			if tries <= 0:
				abort()
			imap.fs.kick_imap(imap)
	return rsp, data

def imap_getquotaroot(imap, fsNameVar):
	tries = 3
	ret = None
	while ret == None:
		tries = tries - 1
		try:
		        ret = imap.getquotaroot(fsNameVar)
		except:
			log_error("imap.getquotaroot() error: %s" % sys.exc_info()[0])
			imap.fs.kick_imap(imap)
			if tries <= 0:
				abort()
	return ret

# The IMAP uid commands can take multiple uids and return
# multiple results
#
# uid here is intended to be an array of uids, and this
# returns a dictionary of results indexed by uid
#
# does python have a ... operator like c preprocessor?
def uid_cmd(imap, cmd, uids, arg1, arg2 = None, arg3 = None):
	# there's something funky going on with gmail.  It seems to not synchronize
	# bewtween different IMAP connections.  You might ask for all the messages
	# in two threads and get different responses.  Running imap.select() seems
	# to synchronize it again.
	imap.select(fsNameVar)
	semget(imap.lock)
	ret = __uid_cmd(imap, cmd, uids, arg1, arg2, arg3)
	imap.lock.release()
	return ret

def __uid_cmd(imap, cmd, uids, arg1, arg2 = None, arg3 = None):
	uids_str = string.join(uids, ",")
	start = time.time()
	log_info("__uid_cmd(%s,...) %d uids" % (cmd, len(uids)))
    	rsp, rsp_data = imap_uid(imap, cmd, uids_str, arg1, arg2, arg3)
	log_imap_time(cmd, start);
	log_info("__uid_cmd(%s, [%s]) ret: '%s'" % (cmd, uids_str, rsp))
	if rsp != "OK":
		log_error("IMAP uid cmd (%s, [%s]) error: %s" % (cmd, uids_str, rsp))
		return None
	ret = {}
	uid_index = 0
	for one_rsp_data in rsp_data:
		log_debug3("rsp_data[%d]: ->%s<-" % (uid_index, one_rsp_data))
		uid_index += 1
	uid_index = 0
	for rsp_nr in range(len(rsp_data)):
		data = rsp_data[rsp_nr]
		# I don't know if this is expected or
		# not, but every other response is just
		# a plain ')' char.  Skip them
		log_debug3("about to lookup uids[%d] data class: '%s'" % (uid_index, data.__class__.__name__))
		if isinstance(data, tuple):
			log_debug4("is tuple")
			for tval in data:
				log_debug4("tval: ->%s<- class: '%s'" % (str(tval), tval.__class__.__name__))
		if isinstance(data, str):
			continue
		uid = uids[uid_index]
		uid_index += 1
		if data == None:
			log_info("uid_cmd(%s) got strange result %s/%s" %
					(cmd, rsp_nr, range(len(rsp_data))))
			continue
		desc = data[0]
		result = data[1]
		ret[uid] = result
	return ret

def clear_rsp_cache():
	global rsp_cache
	log_debug2("clearing rsp cache with %d entries" % (len(rsp_cache)))
	rsp_cache = {}

def imap_trash_uids(imap, raw_uids):
	clear_rsp_cache()
	checked_uids = []
	# there have been a few cases where a -1
	# creeps in here because we're trying to
	# delete a message that has not yet been
	# uploaded to the server.  Filter those
	# out.
	for uid in raw_uids:
		if int(uid) <= 0:
			continue
		checked_uids.append(uid)

	if len(checked_uids) == 0:
		return
	log_imap("imap_trash_uids(%s)" % (string.join(checked_uids,",")))
	ret = uid_cmd(imap, "STORE", checked_uids, '+FLAGS', '\\Deleted')
	global msg_cache
	for uid in checked_uids:
		try:
			del msg_cache[uid]
		except:
			foo = 1
			# this is OK because the msg may neve have
			# been cached
	return ret

def imap_trash_msg(imap, msg):
	if msg.uid <= 0:
		return
	imap_trash_uids(imap, [str(msg.uid)])

def imap_append(info, imap, msg):
	#gmsg = libgmail.GmailComposedMessage(username, subject, body)
	log_imap("imap_append(%s)" % (info))
	log_debug2("append Subject: ->%s<-" % (msg['Subject']))
	log_debug3("entire message: ->%s<-" % str(msg))

	now = imaplib.Time2Internaldate(time.time())
	clear_rsp_cache()
	start = time.time()
	semget(imap.lock)
    	rsp, data = __imap_append(imap, fsNameVar, "", now, str(msg))
	imap.lock.release()
	log_imap_time("APPEND", start);
	log_imap2("append for '%s': rsp,data: '%s' '%s'" % (info, rsp, data))
	if rsp != "OK":
		return -1
	# data looks like this: '['[APPENDUID 631933985 286] (Success)']'
	msgid = int((data[0].split()[2]).replace("]",""))
	msg.uid = msgid
	log_debug("imap msgid: '%d'" % msgid)
	return msgid

def _addLoggingHandlerHelper(handler):
    """ Sets our default formatter on the log handler before adding it to
        the log object. """
    handler.setFormatter(defaultLogFormatter)
    log.addHandler(handler)

def GmailConfig(fname):
    import ConfigParser
    cp = ConfigParser.ConfigParser()
    global References
    global DefaultUsername, DefaultPassword, DefaultFsname
    global NumberQueryRetries
    if cp.read(fname) == []:
      log_warning("Unable to read configuration file: " + str(fname))
      return

    sections = cp.sections()
    if "account" in sections:
      options = cp.options("account")
      if "username" in options:
          DefaultUsername = cp.get("account", "username")
      if "password" in options:
          DefaultPassword = cp.get("account", "password")
    else:
      log.error("Unable to find GMail account configuration")

    if "filesystem" in sections:
      options = cp.options("filesystem")
      if "fsname" in options:
          DefaultFsname = cp.get("filesystem", "fsname")
    else:
      log_warning("Using default file system (Dangerous!)")

    if "logs" in sections:
      options = cp.options("logs")
      if "level" in options:
        level = cp.get("logs", "level")
        log.setLevel(logging._levelNames[level])
      if "logfile" in options:
        logfile = abspath(expanduser(cp.get("logs", "logfile")))
	log.removeHandler(defaultLoggingHandler)
        _addLoggingHandlerHelper(logging.handlers.RotatingFileHandler(logfile, "a", 5242880, 3))

    if "references" in sections:
      options = cp.options("references")
      for option in options:
          record = cp.get("references",option)
          fields = record.split(':')
          if len(fields)<1 or len(fields)>3:
              log_warning("Invalid reference '%s' in configuration." % (record))
              continue
          reference = reference_class(*fields)
          References[option] = reference

do_writeout = 1
#@+node:mythread
class testthread(Thread):
	def __init__ (self, fs, nr):
		Thread.__init__(self)
		self.fs = fs
		self.nr = nr

	def write_out_object(self):
		object = self.fs.get_dirty_object()
		if object == None:
			# the queues are empty, so all is good
			time.sleep(1)
			return 0
		# we do not want to sit here sleeping on objects
		# so if we can not get the lock, move on to another
		# object
		got_lock = object.writeout_lock.acquire(0)
		log_debug3("write out got_lock: '%s' obj dirty: %s" % (str(got_lock), str(object.dirty())))
		if not got_lock:
			dont_block = 1
			self.fs.queue_dirty(object, dont_block)
			return -1
		sem_msg[object.writeout_lock] = "acquired write_out_object()"
		reason = Dirtyable.dirty_reason(object)
    		start = time.time()
		ret = write_out_nolock(object, "bdflushd")
    		end = time.time()
		log_debug3("write out about to releaselock")
		object.writeout_lock.release()
		sem_msg[object.writeout_lock] += " released write_out_object()"
		size = self.fs.dirty_objects.qsize()
		# 0 means it got written out
		# 1 means it was not dirty
		took = end - start
		msg =  "[%d] (%2d sec), %%s %s because '%s' %d left" % (self.nr, took, object.to_str(), reason, size)
		if ret == 0:
			print(msg % ("wrote out"));
		else:
			print(msg % ("did not write"));
		return 1

	def run_writeout(self):
		tries = 5
		for try_nr in range(tries):
			writeout_threads[thread.get_ident()] = "running"
			ret = self.write_out_object()
			#rint("writeout ret: '%s'" % (ret))
			if ret == 0:
				writeout_threads[thread.get_ident()] = "idle"
				msg = "["
				for t in range(self.fs.nr_imap_threads):
					if t >= 1:
						msg += " "
					if writeout_threads[thread.get_ident()] == "idle":
						msg += str(t)
					else:
						msg += " "
				msg += "] idle\r"
				sys.stderr.write(msg)
				sys.stderr.flush()
			if ret >= 0:
				break
			# this will happen when there are
			# objects in the queue for which
			# we can not get the lock.  Do
			# not spin, sleep instead
			if try_nr < tries-1:
				continue

			time.sleep(1)

	def run(self):
		global do_writeout
		writeout_threads[thread.get_ident()] = 1
		log_debug1("mythread: started pid: %d" % (os.getpid()))
		print "connected[%d]" % (self.nr)
		log_debug1("connected[%d]" % (self.nr))
		while do_writeout:
			self.run_writeout()
	       	print "thread[%d] done" % (self.nr)

    #@-node:mythread


class reference_class:
    def __init__(self,fsname,username=None,password=None):
      self.fsname = fsname
      if username is None or username == '':
          self.username = DefaultUsername
      else:
          self.username = username
      if password is None or password == '':
          self.password = DefaultPassword
      else:
          self.password = password

# This ensures backwards compatability where
# old filesystems were stored with 7bit encodings
# but new ones are all quoted printable
def fixQuotedPrintable(body):
    # first remove headers
    newline = body.find("\r\n\r\n")
    if newline >= 0:
	body = body[newline:]
    fixed = body
    if re.search("Content-Transfer-Encoding: quoted",body):
        fixed = quopri.decodestring(body)
    # Map unicode
    return fixed.replace('\u003d','=')

def psub(s):
    if len(s) == 0:
	return "";
    return "SUBJECT \""+s+"\""

def _getMsguidsByQuery(about, imap, queries, or_query = 0):
    or_str = ""
    if or_query:
	or_str = " OR"
    fsq = (str(FsNameTag + "=" + MagicStartDelim + fsNameVar + MagicEndDelim))
    # this is *REALLY* sensitive, at least on gmail
    # Don't put any extra space in it anywhere, or you
    # will be sorry
    #  53:12.12 > MGLK6 SEARCH (SUBJECT "foo=bar" SUBJECT "bar=__fo__o__")
    queryString  = '(SUBJECT "%s"' % (fsq)
    last_q = queries.pop()
    for q in queries:
    	queryString += or_str + ' SUBJECT "%s"' % (q)
    queryString += ' SUBJECT "%s")' % last_q

    global rsp_cache
    global rsp_cache_hits
    global rsp_cache_misses
    if rsp_cache_hits+rsp_cache_misses % 10 == 0:
	    log_info("rsp_cache (size: %d hits: %d misses: %d)" % (len(rsp_cache), rsp_cache_hits, rsp_cache_misses))
    if rsp_cache.has_key(queryString):
	    rsp_cache_hits += 1
	    return rsp_cache[queryString]
    else:
	    rsp_cache_misses += 1

    # make sure mailbox is selected
    log_imap("SEARCH query: '"+queryString+"'")
    start = time.time()
    semget(imap.lock)
    try:
        resp, msgids_list = imap_uid(imap, "SEARCH", None, queryString)
    except:
	log_error("IMAP error on SEARCH")
	log_error("queryString: ->%s<-" % (queryString))
	print "\nIMAP exception, exiting", sys.exc_info()[0]
    	exit(-1)
    finally:
        imap.lock.release()
    log_imap_time("SEARCH", start);
    msgids = msgids_list[0].split(" ")
    log_imap2("search resp: %s msgids len: %d" % (resp, len(msgids)))
    ret = []
    for msgid in msgids:
        log_debug2("IMAP search result msg_uid: '%s'" % str(msgid))
	if len(str(msgid)) > 0:
            ret = msgids
	    break
    if len(rsp_cache) > 1000:
	clear_rsp_cache()
    rsp_cache[queryString] = ret
    return ret

def getSingleMsguidByQuery(imap, q):
        msgids = _getMsguidsByQuery("fillme1", imap, q)
	nr = len(msgids)
        if nr != 1:
	  qstr = string.join(q, " ")
	  # this is debug because it's normal to have non-existent files
          log_debug2("could not find messages for query: '%s' (found %d)" % (qstr, nr))
          return -1;
 	log_debug2("getSingleMsguidByQuery('%s') ret: '%s' nr: %d" % (string.join(q," "), msgids[0], nr))
	return int(msgids[0])

def __fetch_full_messages(imap, msgids):
	if msgids == None or len(msgids) == 0:
		return None
	data = __uid_cmd(imap, "FETCH", msgids, '(RFC822)')
	if data == None:
		return None
	log_imap("fetch(msgids=%s): got %d messages" % (string.join(msgids, ","), len(data)))
	#log_debug2("fetch msgid: '%s' resp: '%s' data: %d bytes" % (str(msgid), resp, len(data)))
	ret = {}
	for uid, raw_str in data.items():
		msg = email.message_from_string(raw_str)
		msg.uid = uid
		ret[str(uid)] = msg
        return ret

msg_cache = {}
def fetch_full_messages(imap, msgids):
	global msg_cache
	ret = {}
	fetch_msgids = []
	# if we do not hold the lock over this entire
	# sequence, we can race and fetch messages
	# twice.  It doesn't hurt, but it is inefficient
	hits = 0
	misses = 0
	semget(imap.lock)
	for msgid in msgids:
		if msgid in msg_cache:
			ret[msgid] = msg_cache[msgid]
			hits += 1
		else:
			fetch_msgids.append(msgid)
			misses += 1
	log_debug3("fetch_full_messages() trying to fetch %d msgs" % (len(fetch_msgids)))
	fetched = None
	if len(fetch_msgids):
		fetched = __fetch_full_messages(imap, fetch_msgids)
	if fetched != None:
		ret.update(fetched)
		for uid, msg in fetched.items():
			if msg_cache.has_key(uid):
				print "uh oh, double-fetched uid: '%s'" % (uid)
			log_debug2("filled msg_cache[%s]" % (str(uid)))
			msg_cache[uid] = msg
	if len(msg_cache) > 1000:
		log_info("flushed message cache")
		msg_cache = {}
	imap.lock.release()
	log_debug3("fetch_full_messages() hits: %d misses: %d" % (hits, misses))
	return ret

def fetch_full_message(imap, msgid):
	resp = fetch_full_messages(imap, [str(msgid)])
	if resp == None:
		return None
	return resp[str(msgid)]

def getSingleMessageByQuery(desc, imap, q):
	log_debug2("getSingleMessageByQuery(%s)" % (desc))
	msgid = getSingleMsguidByQuery(imap, q)
	if msgid == -1:
		log_debug2("getSingleMessageByQuery() msgid: %s" % (str(msgid)))
		return None
	return fetch_full_message(imap, msgid)

def _pathSeparatorEncode(path):
    #s1 = re.sub("/","__fs__",path)
    #s2 = re.sub("-","__mi__",s1)
    return re.sub("\+","__pl__",path)

def _pathSeparatorDecode(path):
    #s1 = re.sub("__fs__","/",path)
    #s2 = re.sub("__mi__","-",s1)
    return re.sub("__pl__","+",path)


def _logException(msg):
    traceback.print_exc(file=sys.stderr)
    log.exception(msg)
    log.info(msg)

# Maybe I'm retarded, but I couldn't get this to work
# with python inheritance.  Oh, well.
def write_out_nolock(o, desc):
	dirty_token = o.dirty()
	if not dirty_token:
		log_debug1("object is not dirty (%s), not writing out" % (str(dirty_token)))
		print("object is not dirty (token: %s), not writing out" % (str(dirty_token)))
		return 1
	#clear_msg = "none"
	clear_msg = o.clear_dirty(dirty_token)
	if   isinstance(o, GmailInode):
		ret = o.i_write_out(desc)
	elif isinstance(o, GmailDirent):
		ret = o.d_write_out(desc)
	elif isinstance(o, GmailBlock):
		ret = o.b_write_out(desc)
	else:
		print("unknown dirty object:"+o.to_str())
	if ret != 0:
		o.mark_dirty("failed writeout");
	log_debug1("write_out() finished '%s' (cleared '%s')" % (desc, clear_msg))
	return ret

def write_out(o, desc):
	# I was seeing situations where a network error (SSL in this case)
	# was raised.  It wasn't handled and the thread died while holding
	# this lock.  This should at least make it release the lock before
	# dying.
	try:
		semget(o.writeout_lock)
		sem_msg[o.writeout_lock] = "acquired write_out()"
		ret = write_out_nolock(o, desc)
	finally:
		o.writeout_lock.release()
		sem_msg[o.writeout_lock] += " released write_out() in exception"
	return ret

class Dirtyable(object):
	def __init__(self):
		log_debug3("Dirtyable.__init__() '%s'" % (self))
		self.dirty_reasons = Queue.Queue(1<<20)
		self.dirty_mark = Queue.Queue(1)
		self.writeout_lock = thread.allocate_lock()
		sem_msg[self.writeout_lock] = "brand spankin new"

	def dirty(self):
    		return self.dirty_reasons.qsize()

	def dirty_reason(self):
    		return "%s (%d more reasons hidden)" % (self.__dirty, self.dirty())

	def clear_dirty(self, nr):
		msgs = []
		log_info("clearing %d dirty reasons" % (nr))
		for msg_nr in range(nr):
			d_msg = self.dirty_reasons.get_nowait()
			log_info("dirty reason[%d]: %s" % (msg_nr, d_msg))
			msgs.append(d_msg)
		msg = "(%s)" % string.join(msgs, ", ")
		# there's a race to do this twice
		orig_reason = self.dirty_mark.get_nowait();
		log_info("cleared original dirty reason: '%s'" % (orig_reason))
		return msg

	def mark_dirty(self, desc, can_block = 1):
		self.__dirty = desc
		self.dirty_reasons.put(desc)
		try:
			self.dirty_mark.put_nowait(desc)
			self.fs.queue_dirty(self, can_block)
		except:
			log_debug("mark_dirty('%s') skipped global list, already dirty" % (self.to_str()))
		log_debug1("mark_dirty('%s') because '%s' (%d reasons, %d total)" %
				(self.to_str(), desc, self.dirty_reasons.qsize(), self.fs.nr_dirty_objects()))

	def to_str(self):
		return "Dirtyable.to_str()"
# end class Dirtyable

#@+node:class GmailDirent
class GmailDirent(Dirtyable):
	def __init__(self, dirent_msg, inode, fs):
        	Dirtyable.__init__(self)
		self.dirent_msg = dirent_msg
		self.inode = inode
		self.fs = fs

	def to_str(self):
		return "dirent('%s' ino=%s)" % (self.path(), str(self.inode.ino))

	def path(self):
		d = self.fs.parse_dirent_msg(self.dirent_msg)
		file = _pathSeparatorDecode(d[FileNameTag])
		path = _pathSeparatorDecode(d[PathNameTag])
		log_debug3("decoded path: '%s' file: '%s'" % (path, file))
		log_debug3("subject was: ->%s<-" % (self.dirent_msg['Subject']))
		# path doesn't have a trailing slash, but the root
		# does have one.  Need to add one when we're dealing
		# with the non-root dir
		if path != "/":
			path += "/"
		return ("%s%s" % (path, file))

	def d_write_out(self, desc):
		log_info("writing out dirent '%s' for '%s' (dirty reason: '%s')"
				% (self.path(), desc, Dirtyable.dirty_reason(self)))
		imap = self.fs.get_imap()
		msgid = imap_append("dirent writeout", imap, self.dirent_msg)
		self.fs.put_imap(imap)
		if msgid <= 0:
		    e = OSError("Could not send mesg in write_out() for: '%s'" % (path))
	            e.errno = ENOSPC
       		    raise e
		return 0

	def d_unlink(self):
		# FIXME, don't allow directory unlinking when children
		log_debug1("unlink path:"+self.path()+" with nlinks:"+str(self.inode.i_nlink))
		if self.inode.mode & S_IFDIR:
			log_debug("unlinking dir")
			# guaranteed not to return any messages to
			# trash since there are two links for dirs
			self.inode.dec_nlink()
		else:
			log_debug("unlinking file")

		to_trash = self.inode.dec_nlink()
		to_trash.append(str(self.dirent_msg.uid))
		if len(to_trash):
			for uid in to_trash:
				log_debug1("unlink() going to trash uid: %s" % (uid))
			imap_trash_uids(self.fs.imap, to_trash)
		semget(self.fs.lookup_lock)
		# this ensures that the (now dead) dentry will never get written out
		while (self.dirty() > 0):
			dirty_token = self.dirty()
			print "d_unlink() dirty token: '%s'" % (dirty_token)
			self.clear_dirty(dirty_token)
		deleted = self.fs.dirent_cache.pop(self.path())
		if deleted != None and deleted != self:
			log_error("[%s] removed wrong dirent from cache self: %s" % (str(thread.get_ident()), str(self)))
			log_error("\tmy path: '%s' uid: '%s' obj: %s" % (self.path(), str(self.dirent_msg.uid), str(self)))
			log_error("\tdl path: '%s' uid: '%s' obj: %s" % (deleted.path(), str(deleted.dirent_msg.uid), str(deleted)))
		self.fs.lookup_lock.release()

		parentdir, name = parse_path(self.path())
	        parentdirinode = self.fs.lookup_inode(parentdir)
	        parentdirinode.i_nlink -= 1
	        parentdirinode.mark_dirty("d_unlink() for parent dir")

#@-node:class GmailDirent

last_ino = -1

# using time for ino is a bad idea FIXME
#
# This helps, but there's still a theoretical
# problem if we mount(), write(), unmount()
# and mount again all within a second.
#
# Should we store this persistently in the
# root inode perhaps?
#
def get_ino():
    global last_ino
    ret = int(time.time()) << 16
    if ret <= last_ino:
	    ret = last_ino + 1
    return int(ret)

#@+node:class GmailInode
class GmailInode(Dirtyable):

    """
    Class used to store gmailfs inode details
    """
    #@+node:__init__
    def __init__(self, inode_msg, fs):
        Dirtyable.__init__(self)
	# We can either make this inode from scratch, or
	# use the inode_msg to fill in all these fields
	self.fs = fs
	self.xattr = {}
	self.i_blocks = {}
	self.inode_cache_lock = thread.allocate_lock()
	# protected by fs.inode_cache_lock
        self.pinned = 0
        if inode_msg != None:
 	    self.inode_msg = inode_msg
            self.fill_from_inode_msg()
	else:
            self.version = 2
            self.ino = get_ino()
            self.mode = 0
            self.dev = 0
            self.i_nlink = 0
            self.uid = 0
            self.gid = 0
            self.size = 0
            self.atime = 0
            self.mtime = 0
            self.ctime = 0
            self.symlink_tgt = ""
            self.block_size = DefaultBlockSize
	    # there are a couple of spots that depend
	    # on having one of these around
	    self.inode_msg = self.mk_inode_msg()
    #@-node:__init__
    def to_str(self):
	    return "inode(%s)" % (str(self.ino))

    def mark_dirty(self, desc, can_block = 1):
	log_debug2("inode mark_dirty(%s) size: '%s'" % (desc, str(self.size)))
        self.mtime = int(time.time())
	Dirtyable.mark_dirty(self, desc, can_block)

    def i_write_out(self, desc):
	log_debug2("i_write_out() self: '%s'" % (self))
	log_info("writing out inode for '%s' (dirty reason: '%s')" % (desc, Dirtyable.dirty_reason(self)))
	for attr in self.xattr:
		value = self.xattr[attr]
		payload_name = 'xattr-'+attr
		log_debug1("adding xattr payload named '%s': '%s'" % (payload_name, value))
		msg_add_payload(self.inode_msg, value, payload_name)
        log_debug3("i_write_out() self.dirty: '%s' desc: '%s'" % (Dirtyable.dirty_reason(self), desc))
	# remember where this is in case we have to delete it
	i_orig_uid = self.inode_msg.uid
	# because this wipes it out
	self.inode_msg = self.mk_inode_msg()
	imap = self.fs.get_imap()
	i_msgid = imap_append("inode writeout", imap, self.inode_msg)
	self.fs.put_imap(imap)
	if i_msgid > 0 and i_orig_uid > 0:
		log_debug("trashing old inode uid: %s new is: %s" % (i_orig_uid, i_msgid))
		imap_trash_uids(imap, [str(i_orig_uid)])
    	if i_msgid <= 0:
            msg = "Unable to write new inode message: '%s'" % (self.inode_msg['Subject'])
            e = OSError(msg)
	    log_error(msg)
            e.errno = ENOSPC
	    abort()
            raise e
    	# Uh oh.  Does this properly truncate data blocks that are no
	# longer in use?
	return 0

    def fill_xattrs(self):
	log_debug3("fill_xattrs()")
	for part in self.inode_msg.get_payload():
		log_debug3("fill_xattrs() loop")
		fname = part.get_filename(None)
		log_debug3("fill_xattrs() fname: '%s'" % (str(fname)))
		if fname == None:
			continue
		m = re.match('xattr-(.*)', fname)
		if m == None:
			continue
		xattr_name = m.group(1)
		log_debug3("fill_xattrs() xattr_name: '%s'" % (xattr_name))
		self.xattr[xattr_name] = part.get_payload(decode=True)

    def mk_inode_msg(self):
   	dev = "11"
        subject = (InodeSubjectPrefix+ " " +
	    	   VersionTag     + "=" + GMAILFS_VERSION+ " " +
                   InodeTag       + "=" + str(self.ino)+ " " +
	           DevTag         + "=" + dev + " " +
		   NumberLinksTag + "=" + str(self.i_nlink)+ " " +
		   FsNameTag      + "=" + MagicStartDelim + fsNameVar +MagicEndDelim +
		   "")
        timeString = str(self.mtime)
	bsize = str(DefaultBlockSize)
	symlink_str = ""
	if self.symlink_tgt != None:
		symlink_str = _pathSeparatorEncode(self.symlink_tgt)
        body = (ModeTag  + "=" + str(self.mode)   + " " +
	        UidTag   + "=" + str(os.getuid()) + " " +
		GidTag   + "=" + str(os.getgid()) + " " +
		SizeTag  + "=" + str(self.size)   + " " +
		AtimeTag + "=" + timeString 	  + " " +
		MtimeTag + "=" + timeString 	  + " " +
		CtimeTag + "=" + timeString 	  + " " +
		BSizeTag + "=" + bsize            + " " +
		SymlinkTag+"=" + LinkStartDelim  + symlink_str + LinkEndDelim +
		"")
	return mkmsg(subject, body)

#yy		  SymlinkTag  + "=" + LinkStartDelim  + str + LinkEndDelim + " " +
#		ret[LinkToTag]   =     m.group(4)
#	link_to  = src_msg_hash[LinkToTag]
    def dec_nlink(self):
	self.i_nlink -= 1
	if self.i_nlink >= 1:
		self.mark_dirty("dec nlink")
		return []
	log_debug2("truncating inode")
	subject = 'b='+str(self.ino)+''
	# either wait until it is fully written out
	got_lock = self.writeout_lock.acquire()
	# or make sure that it never is
	while (self.dirty() > 0):
		dirty_token = self.dirty()
		self.clear_dirty(dirty_token)

	block_uids = _getMsguidsByQuery("unlink blocks", self.fs.imap, [subject])
	to_trash = []
	to_trash.extend(block_uids)
	to_trash.append(str(self.inode_msg.uid))
	self.writeout_lock.release()
	return to_trash

    def fill_from_inode_msg(self):
        """
        Setup the inode instances members from the gmail inode message
        """
	log_debug2("filling inode")
	if self.inode_msg.is_multipart():
		body = self.inode_msg.preamble
		log_debug2("message was multipart, reading body from preamble")
	else:
		# this is a bug
		log_debug2("message was single part")
        log_debug2("body: ->%s<-" % body)
	body = fixQuotedPrintable(body)
	##
	subj_hash = self.fs.parse_inode_msg_subj(self.inode_msg)
        self.version = subj_hash[VersionTag]
        self.ino = int(subj_hash[InodeTag])
	log_debug2("set self.ino to: int: '%d' str: '%s'" % (self.ino, str(subj_hash[InodeTag])))
        self.dev =     subj_hash[DevTag]
        self.i_nlink =   subj_hash[NumberLinksTag]
        #quotedEquals = "=(?:3D)?(.*)"
        quotedEquals = "=(.*)"
	restr = (	  ModeTag  + quotedEquals + ' ' +
			  UidTag   + quotedEquals + ' ' +
	  		  GidTag   + quotedEquals + ' ' +
	                  SizeTag  + quotedEquals + ' ' +
			  AtimeTag + quotedEquals + ' ' +
			  MtimeTag + quotedEquals + ' ' +
	                  CtimeTag + quotedEquals + ' ' +
	                  BSizeTag + quotedEquals + ' ' +
			  SymlinkTag + "=" + LinkStartDelim  + '(.*)' + LinkEndDelim)
        log_debug2("restr: ->%s<-" % (restr))
	m = re.search(re.compile(restr, re.DOTALL), body)
	self.mode  = int(m.group(1))
        self.uid   = int(m.group(2))
        self.gid   = int(m.group(3))
        self.size  = int(m.group(4))
        self.atime = int(m.group(5))
        self.mtime = int(m.group(6))
        self.ctime = int(m.group(7))
        self.block_size = int(m.group(8))
	symlink_tmp    = m.group(9)
	self.symlink_tgt = _pathSeparatorDecode(symlink_tmp)
	log_debug2("filled inode size: %d" % self.size)
	self.fill_xattrs()

#@-node:class GmailInode

#@+node:class OpenGmailFile
class OpenGmailFile():
	def __init__(self, inode):
		self.inode = inode
		self.fs = self.inode.fs
		self.users = 1
        	self.block_size = inode.block_size

	def ts_cmp(self, a, b):
	        return cmp(a.ts, b.ts) # compare as integers

	def prune(self):
		# This locking is a bit coarse.  We could lock
		# just the inode or just OpenGmailFile
		semget(self.inode.fs.inode_cache_lock)
		for i in range(10):
			# We do this so not to unfairly bias against
			# blocks that keep hashing into the low buckets
			skip = random.random() * len(gmail_blocks)
			nr = 0
			for block, g in gmail_blocks.items():
				nr = nr + 1
				if nr < skip:
					continue
				if len(gmail_blocks) > BlockCacheSize:
					break
				if block.dirty():
					continue
				del block.inode.i_blocks[block.block_nr]
				del gmail_blocks[block]
		self.inode.fs.inode_cache_lock.release()
		#print("[%d] file now has %d blocks" % (time.time(), len(self.inode.blocks)))


    	def write(self, buf, off):
		first_block = off / self.block_size
		last_block = (off + len(buf)) / self.block_size

		semget(self.inode.fs.inode_cache_lock)
		for i in range(first_block, last_block+1):
			if not self.inode.i_blocks.has_key(i):
				self.inode.i_blocks[i] = GmailBlock(self.inode, i);
			self.inode.i_blocks[i].write(buf, off)
		self.inode.fs.inode_cache_lock.release()
		self.prune()
		return len(buf)

    	def read(self, readlen, off):
		first_block = off / self.block_size
		last_block = (off + readlen) / self.block_size

		ret = []
		semget(self.inode.fs.inode_cache_lock)
		for i in range(first_block, last_block+1):
			if not self.inode.i_blocks.has_key(i):
				self.inode.i_blocks[i] = GmailBlock(self.inode, i);
			ret += self.inode.i_blocks[i].read(readlen, off)
		self.inode.fs.inode_cache_lock.release()
		self.prune()
		return ret

	def close(self):
	        """
	        Closes this file by committing any changes to the users gmail account
	        """
		self.users -= 1
		if self.users >= 1:
			return self.users
		return 0


gmail_blocks = {}

#@+node:class OpenGmailFile
class GmailBlock(Dirtyable):
    """
    Class holding any currently open files, includes cached instance of the last data block retrieved
    """

    def __init__(self, inode, block_nr):
        Dirtyable.__init__(self)
        self.inode = inode
	self.fs = self.inode.fs

        self.block_size = inode.block_size
        self.buffer = []
	self.buffer_lock = threading.Semaphore(1)
	#list(" "*self.block_size)
        self.block_nr = block_nr
        self.start_offset = self.block_nr * self.block_size
        self.end_offset = self.start_offset + self.block_size
	self.ts = time.time()
	log_debug1("created new GmailBlock: %d for inode: %d" % (self.block_nr, inode.ino))
	gmail_blocks[self] = self

    def to_str(self):
	return "block(%d)" % (self.block_nr)

    def covers(self, off, len):
	# does this block cover the specified buffer?
	if off+len <= self.start_offset:
		return 0;
	if off >= self.end_offset:
		return 0;
	return 1;

    def mypart(self, buf, off):
	if not self.covers(off, len(buf)):
	    return None, None;
	if off >= self.end_offset:
	    # strip off some of the beginning of the buffer
	    to_chop = self.start_offset - off
	    buf = buf[to_chop:]
	    off = self.start_offset
	if off + len(buf) > self.end_offset:
	    new_len = self.block_size - offset
	    buf = buf[:new_len]
	return buf, off

    def write(self, buf, off):
	buf_part, file_off = self.mypart(buf, off)
	log_debug1("write block: %d" % (self.block_nr))
	if buf_part == None or file_off == None:
		return
	log_debug1("my part of buffer: %d bytes, at offset: %d" % (len(buf_part), file_off))

	if (len(buf_part) == self.block_size or
 	    off > self.inode.size):
	    # If we're going to write the whole buffer, do
	    # not bother fetching what we will write over
	    # entirely anyway.
	    semget(self.buffer_lock)
	    self.buffer = list(" "*self.block_size)
	    self.buffer_lock.release()
        else:
	    self.populate_buffer(DELETE_AFTER_READ)

	buf_write_start = file_off - self.start_offset
	buf_write_end = buf_write_start + len(buf_part)
	if buf_write_start < 0:
		print("bad block range: [%d:%d]" % (buf_write_start, buf_write_end))
		print("bad block range: file_off: %d" % (file_off))
		print("bad block range: start_offset: %d" % (self.start_offset))
		print("bad block range: end_offset: %d" % (self.end_offset))
		print("bad block range: buf_write_start: %d" % (buf_write_start))
		print("bad block range: buf_write_end: %d" % (buf_write_end))
		print("bad block range: len(buf_part): %d" % (len(buf_part)))
		print("bad block orig: %d %d" % (len(buf), off))
		abort()

	semget(self.buffer_lock)
	self.buffer[buf_write_start:buf_write_end] = buf_part;
	self.buffer_lock.release()
	log_debug1("wrote block range: [%d:%d]" % (buf_write_start, buf_write_end))

	log_debug1("block write() setting GmailBlock dirty")
	self.mark_dirty("file write")

        if file_off + len(buf_part) > self.inode.size:
            self.inode.size = file_off + len(buf_part)
	    self.inode.mark_dirty("file write extend")
	else:
	    self.inode.mark_dirty("file write")
	self.ts = time.time()
        return len(buf_part)

    def b_write_out(self, desc):
        log_debug1("b_write_out() self.dirty: '%s' desc: '%s'" % (Dirtyable.dirty_reason(self), desc))
	#print("b_write_out() block %d self.dirty: '%s' desc: '%s'" % (self.block_nr, Dirtyable.dirty_reason(self), desc))

    	#a = self.inode.ga
        subject = ('b='+str(self.inode.ino)+
	          ' x='+str(self.block_nr)+
		  ' '+FsNameTag+'='+MagicStartDelim+ fsNameVar +MagicEndDelim )
	tmpf = tempfile.NamedTemporaryFile()

	semget(self.buffer_lock)
	buf = self.buffer
	self.buffer_lock.release()
	if self.inode.size / self.block_size == self.block_nr:
		part = self.inode.size % self.block_size
		log_debug2("on last block, so only writing out %d/%d bytes of block" % (part, len(buf)))
		buf = buf[:part]

        arr = array.array('c')
        arr.fromlist(buf)
	log_debug("wrote contents to tmp file: ->"+arr.tostring()+"<-")

	tmpf.write(arr.tostring())
	tmpf.flush()

	msg = mkmsg(subject, fsNameVar, arr.tostring())
	imap = self.fs.get_imap()
	msgid = imap_append("commit data blocks (%d bytes)" % len(str(msg)), self.inode.fs.imap, msg)
	self.fs.put_imap(imap)
	log_debug("b_write_out() finished, rsp: '%s'" % str(msgid))
	if msgid > 0:
            log_debug("Sent write commit ok")
	    # This is a special case.  This b_write_out() happens in a worker thread,
	    # and if we block it waiting on dirty data to be written out, we may end
	    # up deadlocking.  So, put the inode on a dirty list, but do not block
	    # doing it.
	    can_block = 0
            self.inode.mark_dirty("commit data block", can_block)
	    tmpf.close()
            ret = 0
        else:
            log.error("Sent write commit failed")
	    tmpf.close()
            ret = -3
	return ret

    def read(self, readlen, file_off):
        readlen = min(self.inode.size - file_off, readlen)
	log_debug1("read block: %d" % (self.block_nr))

	self.populate_buffer(KEEP_AFTER_READ)
	start_offset = max(file_off, self.start_offset)
	end_offset   = min(file_off + readlen, self.end_offset)
	start_offset -= self.start_offset
	end_offset   -= self.start_offset

	self.ts = time.time()
	return self.buffer[start_offset:end_offset]

    def populate_buffer(self, deleteAfter):
        """
        Read this data block with from gmail.  If 'deleteAfter' is
        true then the block will be removed from Gmail after reading
        """
	semget(self.buffer_lock)
	if len(self.buffer):
	    self.buffer_lock.release()
	    return
	log_debug2("populate_buffer() filling block %d because len: %d" % (self.block_nr, len(self.buffer)))

        q1 = 'b='+str(self.inode.ino)
	q2 = 'x='+str(self.block_nr)
        msg = getSingleMessageByQuery("block read", self.inode.fs.imap, [ q1, q2 ])
	if msg == None:
	    log_debug2("readFromGmail(): file has no blocks, returning empty contents (%s %s)" % (q1, q2))
	    self.buffer = list(" "*self.block_size)
	    self.buffer_lock.release()
	    return
        log_debug2("got msg with subject:"+msg['Subject'])
	for part in msg.walk():
            log_debug2("message part.get_content_maintype(): '%s'" % part.get_content_maintype())
            if part.get_content_maintype() == 'multipart':
                continue
	    #if part.get('Content-Disposition') is None:
	    #    continue
	    log_debug2("message is multipart")
	    a = part.get_payload(decode = True)
	    log_debug3("part payload has len: %d asstr: '%s'" % (len(a), str(a)))
	log_debug3("after loop, a: '%s'" % str(a))
	a = list(a)

        if deleteAfter == DELETE_AFTER_READ:
 	    log_debug1("populate_buffer() deleting msg: '%s'" % (msg.uid));
            imap_trash_msg(self.inode.fs.imap, msg)
        contentList = list(" "*self.block_size)
        contentList[0:] = a
        self.buffer = contentList
	log_debug2("populate_buffer() filled block %d with len: %d" % (self.block_nr, len(self.buffer)))
	self.buffer_lock.release()

#@-node:class OpenGmailFile

#@+node:class Gmailfs
class Gmailfs(Fuse):

    def kick_imap(self, imap):
	print("kicking imap connection...")
	print("disconnecting...")
	self.disconnect_from_server(imap)
	print("disonnected")
	try:
		sys.stderr.write("connecting to server...")
		self.connect_to_server(imap)
		sys.stderr.write("done\n")
	except Exception, e:
		print("kick connect exception: '%s'" % str(e))
	except:
		print("kick connect unknown exception")

    def disconnect_from_server(self, imap):
	# these are just to be nice to the server.  It
	# does not matter if they succeed because the
	# init below will just blow everything away.
	try:
		imap.close()
		imap.logout()
		imap.shutdown()
	except:
		print("shutdown exception");
	try:
		imap.__init__("imap.gmail.com", 993)
	except:
		print("reconnect exception");

	return

    #@	@+others
    def connect_to_server(self, imap = None):
        global fsNameVar
        global password
        global username

	fsNameVar = DefaultFsname
        password = DefaultPassword
        username = DefaultUsername
	if imap == None:
	        imap = imaplib.IMAP4_SSL("imap.gmail.com", 993)
		imap.fs = self
		imap.lock = threading.Semaphore(1)
	else:
		imap.open("imap.gmail.com", 993) #libgmail.GmailAccount(username, password)
        if username.find("@")<0:
		username = username+"@gmail.com"
        imap.login(username, password)
	resp, data = imap.select(fsNameVar)
	log_debug1("folder select '%s' resp: '%s' data: '%s'" % (fsNameVar, resp, data))
	if resp == "NO":
		log_info("creating mailbox")
		resp, data = imap.create(fsNameVar)
		log_debug1("create '%s' resp: '%s' data: '%s'" % (fsNameVar, resp, data))
		resp, data = imap.select(fsNameVar)
		log_debug1("select2 '%s' resp: '%s' data: '%s'" % (fsNameVar, resp, data))
		return
	return imap

    def get_imap(self):
	if self.early:
		return self.imap
	imap = None
	timeout = 1
	block = 1
	tries = 0

	while imap == None:
		tries = tries + 1
		try:
			imap = self.imap_pool.get(block, timeout)
		except:
			if tries % 10 == 0:
				print("[%d] hung on getting imap worker for %d seconds" % (thread.get_ident(), tries))
				traceback.print_stack()
	return imap

    def put_imap(self, imap):
	if self.early:
		return
	self.imap_pool.put(imap)

    def drain_nonblocking_dirty_queue(self):
	src = self.dirty_objects_nonblocking
	while not src.empty():
		try:
			o = src.get_nowait()
		except Queue.Empty:
			return
		self.queue_dirty_blockable(o)

    # I was getting things blocked on addition to the dirty list.  I thought
    # the writeout threads had died.  But, I put this in and miraculously it
    # started to work ok.  There might be a bug in the blocking Queue.put()
    # that causes it to hang when it shouldn't.  This may work around it.
    def queue_dirty_blockable(self, obj):
	tries = 0
	timeout = 10
	success = 0
	can_block = 1

	while success == 0:
		try:
			self.dirty_objects.put(obj, can_block, timeout)
			success = 1
		except Queue.Full:
			tries = tries + 1
			print("[%d] hung on dirty (%d long) list for %d seconds" %
				(thread.get_ident(), self.dirty_objects.qsize(), tries*timeout))
			traceback.print_stack()

    def queue_dirty(self, obj, can_block = 1):
	if can_block:
		# take the opportunity to move the non-blocking queue
		# over to the blocking one.  The more often you do this
		# the less chance there is for the queue to get too
		# large
		self.drain_nonblocking_dirty_queue()
		self.queue_dirty_blockable(obj)
	else:
		# this one is non-blocking on put()s because it has no
		# size limit
		self.dirty_objects_nonblocking.put(obj)
	log_debug3("end queue_dirty(%s, %d) queue size now: %d/%d" %
			(obj, can_block, self.dirty_objects.qsize(), self.dirty_objects_nonblocking.qsize()))


    def nr_dirty_objects(self):
	size = self.dirty_objects.qsize() + self.dirty_objects_nonblocking.qsize()
	return size

    def get_dirty_object(self):
	try:
		obj = self.dirty_objects.get_nowait()
		log_debug3("get_dirty_object() found one in normal queue: '%s'" % (obj))
		return obj
	except Queue.Empty:
		pass
	try:
		obj = self.dirty_objects_nonblocking.get_nowait()
		log_debug3("get_dirty_object() found one in nonblock queue: '%s'" % (obj))
		return obj
	except Queue.Empty:
		pass
	log_debug3("get_dirty_object() found nothing")
	return None

    def imap_get_all_uids(self, imap):
	semget(imap.lock)
	tmpdebug = imap.debug
	imap.debug = 2
	#imap.close()
	imap.select(fsNameVar)
	resp, msgids = imap_uid(imap, "SEARCH", 'ALL')
	print "imap_get_all_uids: resp: %s msgids: %s" % (resp, msgids)
	uids = msgids[0].split()
	print ("%d messages found..." % (len(uids)))
	imap.lock.release()
	imap.debug = tmpdebug
	return uids

    #@+node:__init__
    def __init__(self, extraOpts, mountpoint, *args, **kw):
        Fuse.__init__(self, *args, **kw)
	self.dirty_objects = Queue.Queue(50)
	self.dirty_objects_nonblocking = Queue.Queue()
	self.lookup_lock = threading.Semaphore(1)
        self.inode_cache_lock = threading.Semaphore(1)

	self.imap = self.connect_to_server()
	self.early = 1;
	if "IMAPFS_FSCK" in os.environ:
		self.fsck()
		exit(0)
	self.early = 0;

    	self.nr_imap_threads = 3
	if "IMAPFS_NR_THREADS" in os.environ:
		self.nr_imap_threads = int(os.environ['IMAPFS_NR_THREADS'])
	self.imap_pool = Queue.Queue(self.nr_imap_threads)
	for i in range(self.nr_imap_threads):
		sys.stderr.write("connecting thread %d to server..." % (i))
		self.imap_pool.put(self.connect_to_server())
		sys.stderr.write("done\n")

        self.fuse_args.mountpoint = mountpoint
	self.fuse_args.setmod('foreground')
	self.optdict = extraOpts
        log_debug("Mountpoint: %s" % mountpoint)
	# obfuscate sensitive fields before logging
	#loggableOptdict = self.optdict.copy()
	#loggableOptdict['password'] = '*' * 8
	#log_info("Named mount options: %s" % (loggableOptdict,))

        # do stuff to set up your filesystem here, if you want

        self.openfiles = {}
        self.flush_dirent_cache()

        global DefaultBlockSize


#	options_required = 1
#	if self.optdict.has_key("reference"):
#	    try:
#		reference = References[self.optdict['reference']]
#		username = reference.username
#		password = reference.password
#		fsNameVar = reference.fsname
#	    except:
#		log.error("Invalid reference supplied. Using defaults.")
#	    else:
#		options_required = 0
#
#        if not self.optdict.has_key("username"):
#	    if options_required:
#	        log_warning('mount: warning, should mount with username=gmailuser option, using default')
#        else:
#            username = self.optdict['username']
#
#        if not self.optdict.has_key("password"):
#	    if options_required:
#        	log_warning('mount: warning, should mount with password=gmailpass option, using default')
#        else:
#            password = self.optdict['password']
#
#        if not self.optdict.has_key("fsname"):
#	    if options_required:
#        	log_warning('mount: warning, should mount with fsname=name option, using default')
#        else:
#            fsNameVar = self.optdict['fsname']
#
#        if self.optdict.has_key("blocksize"):
#            DefaultBlockSize = int(self.optdict['blocksize'])

#04:52.69 CAPABILITIES: ('IMAP4REV1', 'UNSELECT', 'IDLE', 'NAMESPACE', 'QUOTA', 'XLIST', 'CHILDREN', 'XYZZY')
#04:52.97 < * CAPABILITY IMAP4rev1 UNSELECT LITERAL+ IDLE NAMESPACE QUOTA ID XLIST CHILDREN X-GM-EXT-1 UIDPLUS COMPRESS=DEFLATE

	# This select() can be done read-only
	# might be useful for implementing "mount -o ro"
        log_info("Connected to gmail")
	#resp, data = self.imap.list()
	#log_info("list resp: " + resp)
	#for mbox in data:
	#	log_info("mbox: " + mbox)
	#log_info("done listing mboxes")

	#FIXME
	# we should probably make a mkfs command to
	# make the root inode.  We should probably
	# also make it search out and clear all
	# messages with the given label
	#self.imap.debug = 4
	trash_all = 0
	if "IMAPFS_TRASH_ALL" in os.environ:
		trash_all = 1
	if trash_all:
		print("deleting existing messages...")
		uids = self.imap_get_all_uids(self.imap)
		if (len(uids)):
			imap_trash_uids(self.imap, uids)
		print("done deleting %d existing messages" % (len(uids)))
		print("mailbox now has %d messages" % (len(self.imap_get_all_uids(self.imap))))
		semget(self.imap.lock)
		expunged = self.imap.expunge()
		self.imap.lock.release()
		print("mailbox expunged: %s" % str(expunged))
		print("mailbox now has %d messages" % (len(self.imap_get_all_uids(self.imap))))

	self.imap.lock.release()
	print("mailbox has %d messages" % (len(self.imap_get_all_uids(self.imap))))
	#exit(0)
	#elf.mythread()

	log_debug1("init looking for root inode")
	path = "/"
        inode = self.lookup_inode(path)
        if (inode == None) and (path == '/'):
		# I would eventually like to see this done in a mkfs-style command
		log_info("creating root inode")
		mode = S_IFDIR|S_IRUSR|S_IXUSR|S_IWUSR|S_IRGRP|S_IXGRP|S_IXOTH|S_IROTH
        	inode = self.mk_inode(mode, 1)
		# "/" is special and gets an extra link.
		# It will always appear to have an nlink of 3
		# even when it is empty
		inode.i_nlink = inode.i_nlink + 1
		dirent = self.link_inode(path, inode)
		#write_out(inode, "new root inode")
		#write_out(dirent, "new root dirent")
		log_info("root inode uids: %s %s" % (dirent.dirent_msg.uid, inode.inode_msg.uid))
        	inode = self.lookup_inode(path)
		if inode == None:
			log_info("uh oh, can't find root inode")
			exit(-1)

        pass
    #@-node:__init__

    #@+node:attribs
    flags = 1

    def fsck_trash_msg(self, msg):
	if not "IMAPFS_FSCK_CAN_WRITE" in os.environ:
		print "fsck_trash_msg() can not write, so skipping fix"
		return
	imap_trash_msg(self.imap, msg)

    #@-node:attribs
    def fsck(self):
	print ("fsck()")
	self.imap.select(fsNameVar)
	uids = self.imap_get_all_uids(self.imap)
	print ("fsck: %d messages found..." % (len(uids)))
	joined_uids = string.join(uids, ",")
	log_debug1("fsck found msgids: ->%s<-" % (joined_uids))
	if (len(uids) == 0):
		print ("fsck: empty mailbox")
		return
#    def parse_inode_msg_subj(self, inode_msg):
#    def parse_dirent_msg(self, msg):
	# these probably aren't precise enough.  What if a dirent is for a
	# file called "foo_inode_msg_bar"??
	dirent_uids = _getMsguidsByQuery("get all dirents", self.imap, ['dirent_msg '])
	inode_uids =  _getMsguidsByQuery("get all inodes",  self.imap, ['inode_msg '])

	for uid in dirent_uids:
		#subject = msg['Subject']
		print "dirent uid: '%s'" % (uid)
	for uid in inode_uids:
		#subject = msg['Subject']
		print "inode_uid: '%s'" % (uid)

	dir_members = {};
	path_to_dirent = {};
	print "fetching dirent msgs..."
	for msgid, msg in fetch_full_messages(self.imap, dirent_uids).items():
		dirent_parts = self.parse_dirent_msg(msg)
		pathname = _pathSeparatorDecode(dirent_parts[PathNameTag])

		dirent_parts['pathname'] = pathname
		dirent_parts['msg'] = msg

		filename = dirent_parts[FileNameTag]
		if not dir_members.has_key(pathname):
			dir_members[pathname] = {}
		directory = dir_members[pathname]
		if directory.has_key(filename):
			existing = directory[filename]
			print "ERROR: '%s' occurs twice in dir: '%s'" % (filename, pathname)
			if existing['msg'].uid > msgid:
				# throw away the current message that
				# we're looking at
				# and forget that we ever saw it
				self.fsck_trash_msg(msg)
				continue
			else:
				# throw away the message that was there
				self.fsck_trash_msg(existing['msg'])
				# not stricly necessary, but clearer
				directory.pop(filename)
		directory[filename] = dirent_parts
		# are these copy by value or reference??!?!?
		dir_members[pathname] = directory
		print "[%s] found in path '%s': file: '%s'" % (str(msgid), pathname, filename)
		# the "/" dirent has a path of '/' and a filename: ''
		if len(filename) > 0:
			# the path of things under the root dir already end in /
			if len(dirent_parts['pathname']) > 1:
				full = dirent_parts['pathname'] + "/" + filename
			else:
				full = dirent_parts['pathname'] + filename
		else:
			full = "/"
		path_to_dirent[full] = dirent_parts

	inode_refcount = {}
	for full, dirent in path_to_dirent.iteritems():
		ino = dirent[RefInodeTag]
		if not inode_refcount.has_key(ino):
			print "creating refcount for '%s'" % (full)
			inode_refcount[ino] = 1
		else:
			inode_refcount[ino] = inode_refcount[ino] + 1
			print " bumping refcount for '%s' to : %d" % (full, inode_refcount[ino])

		parent_path = dirent['pathname']
		#print "process parent: '%s' for '%s'" % (parent_path, full)
		if not len(parent_path):
			print "WARNING: zero-length parent: '%s' for '%s' hope it's /)" % (parent_path, full)
			continue
		if not path_to_dirent.has_key(parent_path):
			print "ERROR: could not find parent entry '%s'" % (parent_path)
			self.fsck_trash_msg(dirent['msg'])
			continue

	print "second dirent pass, bumping refcounts for parent directories..."
	for full, dirent in path_to_dirent.iteritems():
		parent_path = dirent['pathname']
		parent_dirent = path_to_dirent[parent_path]
		parent_ino = parent_dirent[RefInodeTag]
		#if full == "/":
		#	print "skipping refcount bump for '/', it has enough"
		#	continue
		if not inode_refcount.has_key(parent_ino):
			print "WARNING: parent: '%s' not seen until second dirent pass" % (parent_path)
			inode_refcount[parent_ino] = 0
		inode_refcount[parent_ino] = inode_refcount[parent_ino] + 1
		print "bumping refcount for parent dir of '%s': '%s' to: %d" \
				% (full, parent_path, inode_refcount[parent_ino])


	inodes_seen = {}
	print "fetching all inodes..."
	for msgid, msg in fetch_full_messages(self.imap, inode_uids).items():

		inode_parts = self.parse_inode_msg_subj(msg)
		ino = inode_parts[InodeTag]

		inode_obj = GmailInode(msg, self)
		mode = inode_obj.mode
		if inode_obj.mode & S_IFDIR:
			inode_refcount[ino] = inode_refcount[ino] + 1
			print "bumped refcount for dir ino: %d to : %d" % (ino, inode_refcount[ino])
		inode_obj = None

		log_debug2("msgid: %s has ino: %s" % (msgid, ino))
		if not inode_refcount.has_key(ino):
			# FIXME: link into lost+found dir
			print "ERROR: unlinked inode: '%s'" % (ino)
			self.fsck_trash_msg(msg)
			continue
		if inodes_seen.has_key(ino):
			existing = inodes_seen[ino]
			print "ERROR: duplicate messages for inode: '%s'" % (str(ino))
			if existing['msg'].uid > msgid:
				# throw away the current message that
				# we're looking at
				self.fsck_trash_msg(msg)
				# and forget that we ever saw it
				continue
			else:
				# throw away the message that was there
				self.fsck_trash_msg(existing['msg'])
				# not stricly necessary, but clearer
				inodes_seen.pop(ino)
		inode_parts['msg'] = msg
		inodes_seen[ino] = inode_parts

		stored_nr_links = inode_parts[NumberLinksTag]
		counted_nr_links = inode_refcount[ino]
		if stored_nr_links != counted_nr_links:
			print "WARNING: ino: %s claims to have %s links, but we counted %s" % (ino, stored_nr_links, counted_nr_links)
			#if "IMAPFS_FSCK_CAN_WRITE" in os.environ:
			#	print "fixing inode link count: %s" % (str(ino))
			#	inode = GmailInode(msg, self)
			#	inode.i_nlink = counted_nr_links
			#	inode.mark_dirty("fsck")
			#	inode.i_write_out("fsck")
			continue
		print "GOOD: linked inode: '%s' i_nlink: %d" % (ino, inode_refcount[ino])


    class GmailStat(fuse.Stat):
        def __init__(self):
            self.st_mode = 0
            self.st_ino = 0
            self.st_dev = 0
            self.st_nlink = 0
            self.st_uid = 0
            self.st_gid = 0
            self.st_size = 0
            self.st_atime = 0
            self.st_mtime = 0
            self.st_ctime = 0
            self.st_blocks = 0
	    global IMAPBlockSize
            self.st_blksize = IMAPBlockSize
            self.st_rdev = 0

    #@+node:getattr
    def getattr(self, path):
        st = Gmailfs.GmailStat();
        log_debug2("getattr('%s')" % (path))
        #st_mode (protection bits)
        #st_ino (inode number)
        #st_dev (device)
        #st_nlink (number of hard links)
        #st_uid (user ID of owner)
        #st_gid (group ID of owner)
        #st_size (size of file, in bytes)
        #st_atime (time of most recent access)
        #st_mtime (time of most recent content modification)
        #st_ctime (time of most recent content modification or metadata change).

        inode = self.lookup_inode(path)
        if inode:
	    log_debug3("getattr() 2")
	    log_debug3("found inode for path: '%s'" % (path))
            st.st_mode  = inode.mode
            st.st_ino   = inode.ino
            st.st_dev   = inode.dev
            st.st_nlink = inode.i_nlink
            st.st_uid   = inode.uid
            st.st_gid   = inode.gid
            st.st_size  = inode.size
            st.st_atime = inode.atime
            st.st_mtime = inode.mtime
            st.st_ctme  = inode.ctime
            log_debug3("st.st_mode   = %d" % ( inode.mode))
            log_debug3("st.st_ino    = %d" % ( inode.ino))
            log_debug3("st.st_dev    = %d" % ( inode.dev))
            log_debug3("st.st_nlink  = %d" % ( inode.i_nlink))
            log_debug3("st.st_uid    = %d" % ( inode.uid))
            log_debug3("st.st_gid    = %d" % ( inode.gid))
            log_debug3("st.st_size   = %d" % ( inode.size))
            log_debug3("st.st_atime  = %d" % ( inode.atime))
            log_debug3("st.st_mtime  = %d" % ( inode.mtime))
            log_debug3("st.st_ctme   = %d" % ( inode.ctime))
	    log_debug3("getattr() 3: ->%s<-" % (str(st)))
            return st
    #else:
 	#log_info("getattr ENOENT: '%s'" % (path))
	    #e = OSError("No such file"+path)
	    #e.errno = ENOENT
	    #raise e
        log_debug3("getattr('%s') done" % (path))
	return -ENOENT
    #@-node:getattr

    #@+node:readlink
    def readlink(self, path):
        log_entry("readlink: path='%s'" % path)
        dirent = self.lookup_dirent(path)
	inode = dirent.inode
        if not (inode.mode & S_IFLNK):
            e = OSError("Not a link"+path)
            e.errno = EINVAL
            raise e
        log_debug("about to follow link in body:"+inode.inode_msg.as_string())
	body = fixQuotedPrintable(inode.inode_msg.as_string())
        m = re.search(SymlinkTag+'='+LinkStartDelim+'(.*)'+
                      LinkEndDelim,body)
        link_target = m.group(1)
        link_target = _pathSeparatorDecode(link_target)
	return link_target

    #@-node:readlink

   #@+node:readdir
    def readdir(self, path, offset):
        log_entry("[%d] readdir('%s', %d)" % (thread.get_ident(), path, offset))
        log_debug3("at top of readdir");
        log_debug3("getting dir "+path)
        fspath = _pathSeparatorEncode(path)
        log_debug3("querying for:"+''+PathNameTag+'='+PathStartDelim+
                  fspath+PathEndDelim)
        # FIX need to check if directory exists and return error if it doesnt, actually
        # this may be done for us by fuse
	q = ''+PathNameTag+'='+PathStartDelim+fspath+PathEndDelim
        msgids = _getMsguidsByQuery("readdir", self.imap, [q])
        log_debug3("got readdir msg list")
        lst = []
        for dirlink in ".", "..":
            lst.append(dirlink)

	for c_path, inode in self.dirent_cache.items():
		c_dir, c_file = parse_path(c_path)
		if path != c_dir:
			continue
		# Found "." which we already have
		if len(c_file) == 0:
			continue
		log_debug2("found dir: '%s' file: '%s' for readdir('%s') in inode cache[%s]" % (c_dir, c_file, path, c_path))
		lst.append(c_file)
	for msgid, msg in fetch_full_messages(self.imap, msgids).items():
		subject = msg['Subject']
		#log_debug("thread.summary is " + thread.snippet)
		m = re.search(FileNameTag+'='+FileStartDelim+'(.*)'+
                           FileEndDelim, subject)
		if (m):
			# Match succeeded, we got the whole filename.
			log_debug("Used summary for filename")
			filename = m.group(1)

		log_debug("readdir('%s') found file: '%s'" % (path, filename))
		# this test for length is a special case hack for the root directory to prevent ls /gmail_root
		# returning "". This is hack is requried due to adding modifiable root directory as an afterthought, rather
		# than designed in at the start.
		if len(filename) <=0:
			continue
		filename = _pathSeparatorDecode(filename)
		if lst.count(filename) == 0:
			lst.append(filename)
	log_debug2("readdir('%s') got %d entries" % (path, len(lst)))
        for r in lst:
	    log_debug3("readdir('%s') entry: '%s'" % (path, r))
	    yield fuse.Direntry(r)
    #@-node:getdir

    dirent_cache = {}
    def flush_dirent_cache(self):
	    log_info("flush_dirent_cache()")
	    remove_keys = []
	    for path, dirent in self.dirent_cache.items():
		    log_debug3("dirent_cache[%s]: '%s'" % (path, str(dirent)))
		    if dirent.inode.dirty() or dirent.dirty():
			    continue
		    remove_keys.append(path)
	    for key in remove_keys:
		    dirent = self.dirent_cache[key]
		    del self.dirent_cache[key]
		    self.put_inode(dirent.inode)

	    while 1:
		object = self.get_dirty_object()
		if object == None:
			log_info("no more object to flush")
			break
		write_out(object, "flush_dirent_cache()")
		log_info("flush_dirent_cache() wrote out %s" % (object.to_str()))
		size = self.nr_dirty_objects()
	    log_info("explicit flush done")

    #@+node:unlink
    def unlink(self, path):
        log_entry("unlink called on:"+path)
        try:
            dirent = self.lookup_dirent(path)
	    if dirent == None:
		return -EEXIST
            dirent.d_unlink()
            return 0
        except:
            _logException("Error unlinking file"+path)
            e = OSError("Error unlinking file"+path)
            e.errno = EINVAL
            raise e
    #@-node:unlink

    #@+node:rmdir
    def rmdir(self, path):
        log_debug1("rmdir called on:"+path)
        #this is already checked before rmdir is even called
        #dirlist = self.getdir(path)
        #if len(dirlist)>0:
        #    e = OSError("directory not empty"+path)
        #    e.errno = ENOTEMPTY
        #    raise e
        dirent = self.lookup_dirent(path)
        dirent.d_unlink()

        # update number of links in parent directory
	parentdir, filename = parse_path(path)
        log_debug("about to rmdir with parentdir:"+parentdir)

        parentdirinode = self.lookup_inode(parentdir)
        parentdirinode.dec_nlink()
        return 0

    #@-node:rmdir

    #@+node:symlink
    def symlink(self, oldpath, newpath):
        log_debug1("symlink: oldpath='%s', newpath='%s'" % (oldpath, newpath))
	mode = S_IFLNK|S_IRWXU|S_IRWXG|S_IRWXO
	inode = self.mk_inode(mode, 0)
	inode.symlink_tgt = newpath
	self.link_inode(oldpath, inode)

    #@-node:symlink

    # This provides a single, central place to define the format
    # of the message subjects.  'str' can be something like "%s"
    # to create a printf-style format string for output.  Or, it
    # can be a regex to help with input.
    def format_dirent_subj(self, str):
        # any change in here must be reflected in the two
	# functions below
        subject =(DirentSubjectPrefix+ " " +
		  PathNameTag + "=" + PathStartDelim  + str + PathEndDelim + " " +
		  FileNameTag + "=" + FileStartDelim  + str + FileEndDelim + " " +
                  RefInodeTag + "=" + str      	      + " " +
	          FsNameTag   + "=" + MagicStartDelim + str + MagicEndDelim+ " " +
		  VersionTag  + "=" + str)
	return subject

    def parse_dirent_msg(self, msg):
        subject_re = self.format_dirent_subj('(.*)')
	subject = msg['Subject'].replace("\r\n\t", " ")
        m = re.match(subject_re, subject)
	log_debug3("looking for regex: '%s'" % (subject_re))
	log_debug3("subject: '%s'" % (subject))
	log_debug3("match: '%s'" % (str(m)))
	ret = {}
	# Make sure these match the order of the strings in
	# format_dirent_subj()
	try:
		ret[PathNameTag] =     m.group(1)
 		ret[FileNameTag] =     m.group(2)
		ret[RefInodeTag] = int(m.group(3))
		ret[FsNameTag]   =     m.group(4)
		ret[VersionTag]  = int(m.group(5))
	except:
		log_error("unable to match regex\n\n\n\n")
		ret = None
	if ret[FsNameTag] != fsNameVar:
		log_error("msgid[%s] wrong filesystem: '%s'" % (msg.uid, ret[FsNameTag]))
		return None
	if ret[VersionTag] != int(GMAILFS_VERSION):
		log_error("msgid[%s] wrong version: '%s', expected '%d'" % (msg.uid, ret[VersionTag], int(GMAILFS_VERSION)))
		return None
	for key, val in ret.items():
		log_debug3("parse_dirent_msg() ret[%s]: '%s'" % (key, val))
	return ret;

    def mk_dirent_msg(self, path, inode_nr_ref):
	log_debug1("mk_dirent_msg('%s', 'ino=%s')" % (path, str(inode_nr_ref)))
	body = ""
	path, filename = parse_path(path)

	path = _pathSeparatorEncode(path)
	filename = _pathSeparatorEncode(filename)
	# again, make sure these are all in the correct order
	subject = self.format_dirent_subj("%s") % (
			path,
			filename,
			inode_nr_ref,
			fsNameVar,
			GMAILFS_VERSION)
	msg = mkmsg(subject, body)
	log_debug1("mk_dirent_msg('%s', 'ino=%s') done" % (path, str(inode_nr_ref)))
	return msg

    def parse_inode_msg_subj(self, inode_msg):
            subject = inode_msg['Subject'].replace('\u003d','=')
            log_debug3("parsing inode from subject:"+subject)
    	    ret = {}
            m = re.match((InodeSubjectPrefix+' '+
			  VersionTag+'=(.*) '+
			  InodeTag+'=(.*) '+
			  DevTag+'=(.*) '+
			  NumberLinksTag+'=(.*) '+
			  FsNameTag+'='+MagicStartDelim+'(.*)'+MagicEndDelim),
			 subject)
	    if m == None:
	    	return None
            ret[VersionTag]     = int(m.group(1))
	    ret[InodeTag]       = int(m.group(2))
	    ret[DevTag]         = int(m.group(3))
	    ret[NumberLinksTag] = int(m.group(4))
	    return ret


    #@+node:rename
    def rename(self, path_src, path_dst):
        log_debug1("rename from: '%s' -> '%s'" % (path_src, path_dst))
        src_dirent = self.lookup_dirent(path_src)
	if src_dirent == None:
		return -ENOENT

	dst_dirent = self.lookup_dirent(path_dst)
	if not dst_dirent == None:
		dst_dirent.d_unlink()
	# ensure the inode does not go away between
	# when we unlink and relink it
	inode = self.get_inode(src_dirent.inode.ino)
	# do the unlink first, because otherwise we
	# will get two dirents at the same path
	src_dirent.d_unlink()
	self.link_inode(path_dst, inode)
	self.put_inode(inode)

    #@-node:rename

    #@+node:link
    def link(self, old_path, new_path):
        log_entry("hard link: old_path='%s', new_path='%s'" % (old_path, new_path))
        inode = self.lookup_inode(old_path)
        if not (inode.mode & S_IFREG):
            e = OSError("hard links only supported for regular files not directories:"+oldpath)
            e.errno = EPERM
            raise e
        inode.mark_dirty("link")
	link_to(new_path, inode)
        return 0
    #@-node:link

    #@+node:chmod
    def chmod(self, path, mode):
        log_entry("chmod('%s', %o)" % (path, mode))
        inode = self.lookup_inode(path)
        inode.mode = (inode.mode & ~(S_ISUID|S_ISGID|S_ISVTX|S_IRWXU|S_IRWXG|S_IRWXO)) | mode
        inode.mark_dirty("chmod")
        return 0
    #@-node:chmod

    #@+node:chown
    def chown(self, path, user, group):
        log_entry("chown called with user:"+str(user)+" and group:"+str(group))
        inode = self.lookup_inode(path)
        inode.uid = user
        inode.gid = group
        inode.mark_dirty("chown")
        return 0
    #@-node:chown

    #@+node:truncate
    def truncate(self, path, size):
        inode = self.lookup_inode(path)
        log_entry("truncate '%s' to size: '%d' from '%d'" % (path, size, inode.size))
        # this is VERY lazy, we leave the truncated data around
        # it WILL be harvested when we grow the file again or
        # when we delete the file but should probably FIX
	if inode.size != size:
	        inode.size = size;
        	inode.mark_dirty("truncate")
        return 0
    #@-node:truncate

    #@+node:getxattr
    def getxattr(self, path, attr, size):
        log_entry("getxattr('%s', '%s', '%s')" % (path, attr, size))
        inode = self.lookup_inode(path)
	# TODO check to make sure we don't overflow size
	if attr not in inode.xattr:
		return -ENODATA
	ret = inode.xattr[attr]
	if size == 0:
		return len(ret)
        return ret
    #@-node:getxattr

    #@+node:setxattr
    def setxattr(self, path, attr, value, dunno):
        log_entry("setxattr('%s', '%s', '%s', '%s')" % (path, attr, value, dunno))
        inode = self.lookup_inode(path)
	inode.xattr[attr] = value
	inode.mark_dirty("setxattr")
    	return 0
    #@-node:setxattr

    #@+node:removexattr
    def removexattr(self, path, attr, value, dunno):
        log_entry("removexattr('%s', '%s')" % (path, attr))
        inode = self.lookup_dirent(path)/inode
	try:
		del inode.xattr[attr]
	except:
		return -ENOATTR
	inode.mark_dirty("removexattr")
    	return 0
    #@-node:removexattr

    #@+node:listxattr
    def listxattr(self, path, size):
        log_entry("listxattr('%s', '%s')" % (path, size))
        inode = self.lookup_inode(path)
	# We use the "user" namespace to please XFS utils
	attrs = []
	for attr in inode.xattr:
	        log_debug1("listxattr() attr: '%s'" % (attr))
		attrs.append(attr)
	if size == 0:
		# We are asked for size of the attr list, ie. joint size of attrs
		# plus null separators.
		return len("".join(attrs)) + len(attrs)
    	log_debug1("all attrs: (%s)" % (string.join(attrs, ", ")))
	return attrs
    #@-node:listxattr

    #@+node:mknod
    def mknod(self, path, mode, dev):
    	""" Python has no os.mknod, so we can only do some things """
        log_entry("mknod('%s')" % (path))
	if S_ISREG(mode) | S_ISFIFO(mode) | S_ISSOCK(mode):
	    inode = self.mk_inode(mode, 0)
	    self.link_inode(path, inode)
	    # update parent dir??
    	    #open(path, "w")
    	else:
    		return -EINVAL
    #@-node:mknod

    def mk_dirent(self, inode, path):
	# this should keep us from racing with lookup_dirent()
	semget(self.lookup_lock)
	if self.dirent_cache.has_key(path):
		log_debug("dirent cache hit on path: '%s'" % (path))
		return self.dirent_cache[path]
	filename, dir = parse_path(path)
	msg = self.mk_dirent_msg(path, inode.ino)
	log_debug1("mk_dirent_msg(%s) done" % path)
	dirent = GmailDirent(msg, inode, self)
	log_debug1("GmailDirent(%s) done" % path)
	dirent.mark_dirty("mk_dirent")
	log_debug1("mark_dirty '%s' done" % path)
	if len(self.dirent_cache) > 1000:
                self.flush_dirent_cache()
		log_debug1("cache flush '%s' done" % path)
	log_debug1("added dirent to cache for path: '%s'" % (dirent.path()))
        self.dirent_cache[dirent.path()] = dirent
	self.lookup_lock.release()
	log_debug1("mk_dirent('%s') lock released" % path)
	return dirent

    def mk_inode(self, mode, size):
	inode = GmailInode(None, self)
	inode.mode = int(mode)
	inode.size = int(size)
	inode.i_nlink = 0
	inode.mark_dirty("new inode")
	self.inode_cache[inode.ino] = inode
	return inode

    def link_inode(self, path, inode):
	dirent = self.mk_dirent(inode, path)
	inode.i_nlink = inode.i_nlink + 1
	inode.mark_dirty("link_inode()")

	parentdir, name = parse_path(path)
	log_debug1("mkdir() parentdir: '%s' name: '%s'" % (parentdir, name))
        parentdirinode = self.lookup_inode(parentdir)
        parentdirinode.i_nlink += 1
        parentdirinode.mark_dirty("link_inode() for parent dir")
	return dirent

    def lookup_inode(self, path):
    	dirent = self.lookup_dirent(path)
	if dirent == None:
		log_debug2("no dirent for path: '%s'" % (path))
		return None
	return dirent.inode

    #@+node:mkdir
    def mkdir(self, path, mode):
        log_entry("mkdir('%s', %o)" % (path, mode))
	if (self.lookup_dirent(path) != None):
		return -EEXIST
        inode = self.mk_inode(mode|S_IFDIR, 1)
	# extra link for for '.'
	inode.i_nlink = inode.i_nlink + 1
	self.link_inode(path, inode)
    #@-node:mkdir

    #@+node:utime
    def utime(self, path, times):
        log_entry("utime for path:"+path+" times:"+str(times))
        inode = self.lookup_inode(path)
        inode.atime = times[0]
        inode.mtime = times[1]
        return 0
    #@-node:utime

    #@+node:open
    def open(self, path, flags):
        log_entry("gmailfs.py:Gmailfs:open: %s" % path)
        try:
            inode = self.lookup_inode(path)
	    # If the same file is opened twice, use the
	    # existing entry.  I'm not sure how
	    # semantically correct this is.  Seems like
	    # it could cause problems down the road.
	    # Who knows...
	    if self.openfiles.has_key(path):
	    	self.openfiles[path].users += 1
	    else:
		f = OpenGmailFile(inode)
		self.openfiles[path] = f
            return 0
        except:
	    _logException("Error opening file: "+path)
	    e = OSError("Error opening file: "+path)
            e.errno = EINVAL
            raise e
    #@-node:open

    #@+node:read
    def read(self, path, readlen, offset):
        try:
 	    log_debug1("gmailfs.py:Gmailfs:read(len=%d, offset=%d, path='%s')"
			    % (readlen, offset, path))
            f = self.openfiles[path]
            buf = f.read(readlen,offset)
            arr = array.array('c')
            arr.fromlist(buf)
            rets = arr.tostring()

            return rets
        except:
            _logException("Error reading file"+path)
            e = OSError("Error reading file"+path)
            e.errno = EINVAL
            raise e
    #@-node:read

    #@+node:write
    def write(self, path, buf, off):
	log_entry("write('%s', len:%d, off:%d)" % (path, len(buf), off))
        try:
            if log.isEnabledFor(logging.DEBUG):
                log_debug3("writing file contents: ->"+str(buf)+"<-")
            f = self.openfiles[path]
            written = f.write(buf,off)
	    log_debug2("wrote %d bytes to file: '%s'" % (written, f))
    	    return written
        except:
            _logException("Error opening file"+path)
            e = OSError("Error opening file"+path)
            e.errno = EINVAL
            raise e
    #@-node:write

    #@+node:release
    def release(self, path, flags):
        log_entry("gmailfs.py:Gmailfs:release: %s %x" % (path, int(flags)))
	# I saw a KeyError get thrown out of this once.  Looking back in
	# the logs, I saw two consecutive release:
	# 01/20/10 17:47:47 INFO       gmailfs.py:Gmailfs:release: /linux-2.6.git/.Makefile.swp 32768
	# 01/20/10 17:47:49 INFO       gmailfs.py:Gmailfs:release: /linux-2.6.git/.Makefile.swp 32769
	#
        f = self.openfiles[path]
	if f.close() == 0:
		#write_out(f, "release")
		# This write_out() is really slowing things down.
		#
		# Without it, there is a race:
		# 1. write() and queue file in dirty writeout queue for block write
		# 2. close(), and get in here
		# 3. remove file from openfiles[]
		# 4. new open(), and make a new OpenGmailFile created since
		#    openfiles[] no longer has an entry
		# 5. Write the same data block that is pending for write above...
		#    we won't find the first one
		#
		# Do we need to make a link from inode->data blocks waiting for
		# writeout?
		del self.openfiles[path]
        return 0
    #@-node:release

    def get_quota_info(self):
	# not really interesting because we don't care how much
	# is in the entire account, just our particular folder
	#resp, data = self.imap.getquota("")

	# response looks like:
	# [['"linux_fs_3" ""'], ['"" (STORAGE 368 217307895)']]
	# numbers are in 1k-sized blocks
	imap = self.get_imap()
	resp, data = imap_getquotaroot(imap, fsNameVar)
	self.put_imap(imap)
	storage = data[1][0]
	m = re.match('"" \(STORAGE (.*) (.*)\)', storage)
	used_blocks = int(m.group(1))
	allowed_blocks = int(m.group(2))
	log_imap("quota resp: '%s'/'%s'" % (resp, data))
	return [used_blocks * 1024, allowed_blocks * 1024]


    #@+node:statfs
    def statfs(self):
	log_entry("statfs()")
        """
        Should return a tuple with the following 6 elements:
            - blocksize - size of file blocks, in bytes
            - totalblocks - total number of blocks in the filesystem
            - freeblocks - number of free blocks
            - availblocks - number of blocks available to non-superuser
            - totalfiles - total number of file inodes
            - freefiles - nunber of free file inodes

        Feel free to set any of the above values to 0, which tells
        the kernel that the info is not available.
        """
        st = fuse.StatVfs()
        block_size = 1024
        quotaBytesUsed, quotaBytesTotal = self.get_quota_info()
        blocks = quotaBytesTotal / block_size
        quotaPercent = 100.0 * quotaBytesUsed / quotaBytesTotal
        blocks_free = (quotaBytesTotal - quotaBytesUsed) / block_size
        blocks_avail = blocks_free # I guess...
        log_debug("%s of %s used. (%s)\n" % (quotaBytesUsed, quotaBytesTotal, quotaPercent))
        log_debug("Blocks: %s free, %s total\n" % (blocks_free, blocks))
        files = 0
        files_free = 0
        namelen = 80
        st.f_bsize = block_size
	st.f_frsize = block_size
	st.f_blocks = blocks
	st.f_bfree = blocks_free
	st.f_bavail = blocks_avail
	st.f_files = files
	st.f_ffree = files_free
       	if "IMAPFS_FSCK_ON_STATFS" in os.environ:
		print "now fscking"
		self.fsck()
	return st
    #@-node:statfs

    #@+node:fsync
    def fsync(self, path, isfsyncfile):
        log_entry("gmailfs.py:Gmailfs:fsync: path=%s, isfsyncfile=%s" % (path, isfsyncfile))
        log_info("gmailfs.py:Gmailfs:fsync: path=%s, isfsyncfile=%s" % (path, isfsyncfile))
        inode = self.lookup_inode(path)
        f = self.openfiles[path]
	write_out(inode, "fsync_inode")
	#for block in inode._blocks:
	#        write_out(block, "fsync_blocks")
       	if "IMAPFS_FSCK_ON_FLUSH" in os.environ:
		print "now fscking"
		self.fsck()
        return 0
    #@-node:fsync

    #@+node:fsync
    def fsyncdir(self, path, isfsyncfile):
        log_entry("gmailfs.py:Gmailfs:fsyncdir: path=%s, isfsyncfile=%s" % (path, isfsyncfile))
        log_info("gmailfs.py:Gmailfs:fsyncdir: path=%s, isfsyncfile=%s" % (path, isfsyncfile))
       	if "IMAPFS_FSCK_ON_FLUSH" in os.environ:
		print "now fscking"
		self.fsck()
	return -ENOSYS

    #@-node:fsync

    #@+node:fsync
    def flush(self, path):
        log_entry("gmailfs.py:Gmailfs:flush: path=%s" % (path))
        dirent = self.lookup_dirent(path)
	#write_out(dirent, "flush")
	#write_out(dirent.inode, "flush")
	while self.nr_dirty_objects() > 0:
		print "there are still dirty objects, sleeping..."
		time.sleep(1)
	if "IMAPFS_FSCK_ON_FLUSH" in os.environ:
		print "now fscking"
		self.fsck()
        return 0
    #@-node:fsync

    def fetch_dirent_msgs_for_path(self, dir_path):
	log_debug2("fetch_dirent_msgs_for_path('%s')" % (dir_path))
	encoded_path = _pathSeparatorEncode(dir_path)
	q = "" + PathNameTag + '=' + PathStartDelim + encoded_path + PathEndDelim
	about = ("dirent lookup('%s')" % (dir_path))
        dirent_msgids = _getMsguidsByQuery(about, self.imap, [q])
	log_debug2("q: '%s'" % (q))
	if len(dirent_msgids) == 0:
		log_debug2("could not find messages for path: '%s'" % (dir_path))
		return None
	log_debug2("fetch_dirent_msgs_for_path('%s') got back '%d' responses" % (dir_path, len(dirent_msgids)))
	return dirent_msgids

    def fetch_dirent_msg_for_path(self, path):
	if self.dirent_cache.has_key(path):
		return self.dirent_cache[path].dirent_msg
	else:
		log_debug2("fetch_dirent_msg_for_path('%s') missed the inode cache()" % (path))
		for path, inode in self.dirent_cache.items():
			log_debug3("in cache: '%s'" % (path))
	dirent_msgids = fetch_dirent_msg_for_path(dirpath)
	return dirent_msgids[0]

    inode_cache = {}
    inode_cache_lock = None
    def find_or_mk_inode(self, ino, msg):
	ino = int(ino)
	semget(self.inode_cache_lock)
	if len(inode_cache) > 1000:
		log_info("flushing inode cache")
		new_inode_cache = {}
		for ino, inode in self.inode_cache:
			if inode.pinned < 1:
				continue
			new_inode_cache[ino] = inode
		self.inode_cache = new_inode_cache
	if self.inode_cache.has_key(ino):
		inode = self.inode_cache[ino]
	else:
	        inode = GmailInode(msg, self)
		self.inode_cache[ino] = inode
	self.inode_cache_lock.release()
	return inode

    def dirent_msg_iref(self, dirent_msg):
	dirent_msg_hash = self.parse_dirent_msg(dirent_msg)
	if dirent_msg_hash == None:
	    	log_debug1("lookup_dirent() failed to parse dirent_msg for uid '%s'" % (dirent_msg.uid))
		return None
       	return str(dirent_msg_hash[RefInodeTag])

    def get_inode(self, ino):
	ino = int(ino)
	semget(self.inode_cache_lock)
	if not self.inode_cache.has_key(ino):
		self.inode_cache_lock.release()
		return None
	inode = self.inode_cache[ino]
	inode.pinned += 1
	self.inode_cache_lock.release()
	return inode

    def put_inode(self, inode):
	semget(self.inode_cache_lock)
	inode.pinned -= 1
	self.inode_cache_lock.release()

    def mk_pinned_inode(self, msg):
	subj_hash = self.parse_inode_msg_subj(msg)
	ino = int(subj_hash[InodeTag])
        ret = None
	semget(self.inode_cache_lock)
	if self.inode_cache.has_key(ino):
		ret = self.inode_cache[ino]
		log_debug2("pinned new inode nr: '%s'" % (str(ret.ino)))
	else:
		ret = GmailInode(msg, self)
		self.inode_cache[ret.ino] = ret
		log_debug2("pinned new inode nr: '%s'" % (str(ret.ino)))
	ret.pinned += 1
	self.inode_cache_lock.release()
	return ret

    def mk_pinned_inodes(self, msgs):
	inodes = []
	for uid, msg in msgs.items():
		inode = self.mk_pinned_inode(msg)
		inodes.append(inode)
	return inodes

    def mk_iref_query(self, dirent_msgs):
        query = []
        inodes = []
	dirent_msgs_by_iref = {}
	for uid, dirent_msg in dirent_msgs.items():
		iref = self.dirent_msg_iref(dirent_msg)
		dirent_msgs_by_iref[iref] = dirent_msg
		inode = self.get_inode(iref)
		if not inode == None:
			inodes.append(inode)
			continue
    		query.append(InodeTag+'='+iref)
	return dirent_msgs_by_iref, query, inodes

    def prefetch_dirent_msgs(self, dir):
	log_debug3("prefetch_dirent_msgs() 0")
    	dirent_msgids = self.fetch_dirent_msgs_for_path(dir)
        if dirent_msgids == None:
            return None

	log_debug2("prefetch_dirent_msgs('%s') going to fetch '%d' msgs" % (dir, len(dirent_msgids)))
    	dirent_msgs = fetch_full_messages(self.imap, dirent_msgids)
	log_debug1("prefetch_dirent_msgs('%s') got back '%d' msgs" % (dir, len(dirent_msgs)))

	dirent_msgs_by_iref, query, inodes = self.mk_iref_query(dirent_msgs)

	if len(query):
		inode_msguids = _getMsguidsByQuery("batch inode lookup", self.imap, query, 1)
		i_msgs = fetch_full_messages(self.imap, inode_msguids)
		inodes.extend(self.mk_pinned_inodes(i_msgs))

	log_debug3("prefetch_dirent_msgs() end")
	return dirent_msgs_by_iref

    def lookup_dirent(self, path):
        if (len(path) > PATHNAME_MAX):
		e = OSError("Pathname too long:"+path)
		e.errno = ENAMETOOLONG
		print("ENAMETOOLONG")
		traceback.print_stack()
		raise e

	dir, filename = parse_path(path)
	# This cache checking is required at this point.  There
	# are inodes in the cache that have not been written to
	# storage, and will not show up when we do
	# self.fetch_dirent_msgs_for_path(), we must get them
	# from here.
        if self.dirent_cache.has_key(path):
            return self.dirent_cache[path]

	# We don't want to be simultaneously prefetching the same
	# messages in two different threads.  So, serialize the
	# lookups for now.
	semget(self.lookup_lock)
	dirent_msgs_by_iref = self.prefetch_dirent_msgs(dir)
	if dirent_msgs_by_iref == None:
		self.lookup_lock.release()
		return None

        ret_dirent = None
	for iref, dirent_msg in dirent_msgs_by_iref.items():
		iref = int(iref)
		# no locking needed since we've already
		# pinned it
		if self.inode_cache.has_key(iref):
			inode = self.inode_cache[iref]
		else:
			log_error("dirent_msg (%s) refers to ino=%d which was not fetched" % (dirent_msg.uid, iref))
			log_error("dirent_msg subject: ->%s<-" % (dirent_msg['Subject']))
			continue
		new_dirent = GmailDirent(dirent_msg, inode, self)
		log_debug2("cached dirent: '%s'" % (new_dirent.path()))
		if self.dirent_cache.has_key(new_dirent.path()):
			new_dirent = self.dirent_cache[new_dirent.path()]
		else:
		       	self.dirent_cache[new_dirent.path()] = new_dirent
		if new_dirent.path() == path:
			log_debug2("lookup_dirent() dirent: '%s'" % (new_dirent.path()))
			ret_dirent = new_dirent
	self.lookup_lock.release()
        return ret_dirent

    #@-others

#@-node:class Gmailfs
#@+node:mainline

# Setup logging
log = logging.getLogger('gmailfs')
#defaultLogLevel = logging.WARNING
defaultLogLevel = logging.DEBUG
log.setLevel(defaultLogLevel)
defaultLogFormatter = logging.Formatter("%(asctime)s %(levelname)-10s %(message)s", "%x %X")

# log to stdout while parsing the config while
defaultLoggingHandler = logging.StreamHandler(sys.stdout)
_addLoggingHandlerHelper(defaultLoggingHandler)

GmailConfig([SystemConfigFile,UserConfigFile])
try:
    libgmail.ConfigLogs(log)
except:
    pass

def main(mountpoint, namedOptions):
    log_debug1("Gmailfs: starting up, pid: %d" % (os.getpid()))
    global lead_thread
    lead_thread = thread.get_ident()
    if am_lead_thread():
	    print "am lead thread"
    else:
	    print "am NOT lead thread"
    server = Gmailfs(namedOptions,mountpoint,version="gmailfs 0.8.0",usage='',dash_s_do='setsingle')
    server.parser.mountpoint = mountpoint
    server.parse(errex=1)
    server.flags = 0
    #server.multithreaded = False;
    server.multithreaded = True;
    writeout_threads = []
    for i in range(server.nr_imap_threads):
	    t = testthread(server, i)
	    t.start()
	    writeout_threads.append(t)
    server.main()
    global do_writeout
    do_writeout = 0
    for t in writeout_threads:
	    print "joining thread..."
	    t.join()
	    print "done joining thread"
    log_info("unmount: flushing caches")
    server.flush_dirent_cache()
    imap_times_print(1)
    log_info("done")

if __name__ == '__main__':
    main(1, "2")

#@-node:mainline
#@-others
#@-node:@file gmailfs.py
#@-leo
