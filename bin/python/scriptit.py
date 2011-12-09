#!/usr/bin/env python
# -*- coding: utf-8 -*-
#
# scriptit.py
#
# Nicolargo (aka) Nicolas Hennion
# http://www.nicolargo.com
#

"""
Python skeleton for speed up development of auto/post installation script.
"""

import os, sys, platform, getopt, shutil, logging, getpass

# Global variables
#-----------------------------------------------------------------------------

_VERSION="0.1"
_DEBUG = 0

# Classes
#-----------------------------------------------------------------------------

class colors:
	RED = '\033[91m'
	GREEN = '\033[92m'
	BLUE = '\033[94m'
	ORANGE = '\033[93m'
	NO = '\033[0m'

	def disable(self):
		self.RED = ''
		self.GREEN = ''
		self.BLUE = ''
		self.ORANGE = ''
		self.NO = ''

# Functions
#-----------------------------------------------------------------------------

def init():
	"""
	Init the script
	"""
	# Globals variables
	global _VERSION
	global _DEBUG

	# Set the log configuration
	logging.basicConfig(
		filename='/tmp/scripit.log',
		level=logging.DEBUG,
		format='%(asctime)s %(levelname)s - %(message)s',
	 	datefmt='%d/%m/%Y %H:%M:%S',
	 )

def syntax():
	"""
	Print the script syntax
	"""
	print "TODO Syntax..."

def version():
	"""
	Print the script version
	"""
	sys.stdout.write ("Script version %s" % _VERSION)
	sys.stdout.write (" (running on %s %s)\n" % (platform.system() , platform.machine()))

def showexec(description, command, exitonerror = 0):
	"""
	Exec a system command with a pretty status display (Running / Ok / Warning / Error)
	By default (exitcode=0), the function did not exit if the command failed
	"""

	if _DEBUG: 
		logging.debug ("%s" % description)
		logging.debug ("%s" % command)

	# Manage very long description
	if (len(description) > 65):
		description = description[0:65] + "..."
		
	# Display the command
	status = "[Running]"
	statuscolor = colors.BLUE
	sys.stdout.write (colors.NO + "%s" % description + statuscolor + "%s" % status.rjust(79-len(description)) + colors.NO)
	sys.stdout.flush()

	# Run the command
	returncode = os.system ("/bin/sh -c \"%s\" >> /dev/null 2>&1" % command)
	
	# Display the result
	if returncode == 0:
		status = "[  OK   ]"
		statuscolor = colors.GREEN
	else:
		if exitonerror == 0:
			status = "[Warning]"
			statuscolor = colors.ORANGE
		else:
			status = "[ Error ]"
			statuscolor = colors.RED

	sys.stdout.write (colors.NO + "\r%s" % description + statuscolor + "%s\n" % status.rjust(79-len(description)) + colors.NO)

	if _DEBUG: 
		logging.debug ("Returncode = %d" % returncode)

	# Stop the program if returncode and exitonerror != 0
	if ((returncode != 0) & (exitonerror != 0)):
		if _DEBUG: 
			logging.debug ("Forced to quit")
		exit(exitonerror)

def getpassword(description = ""):
	"""
	Read password (with confirmation)
	"""
	if (description != ""): 
		sys.stdout.write ("%s\n" % description)
		
	password1 = getpass.getpass("Password: ");
	password2 = getpass.getpass("Password (confirm): ");

	if (password1 == password2):
		return password1
	else:
		sys.stdout.write (colors.ORANGE + "[Warning] Password did not match, please try again" + colors.NO + "\n")
		return getpassword()
		
def main(argv):
	"""
	Main function
	"""
	# logging.info("Start")
	# logging.warning("Warning")
	# logging.debug("Debug")
	# logging.info("End")

	try:
		opts, args = getopt.getopt(argv, "hvd", ["help", "version", "debug"])
	except getopt.GetoptError:
		syntax()
		exit(2)

	for opt, arg in opts:
		if opt in ("-h", "--help"):
			syntax()
			exit()
		elif opt == '-v':
			version()
			exit()
		elif opt == '-d':
			global _DEBUG
			_DEBUG = 1

	#	pw = getpassword ("Enter a dummy password...")
	showexec ("File list", "/bin/ls")
	showexec ("A very very very long description for this little command too long description will be cutted", "/bin/ls")
	showexec ("Noexist command but continue", "noexist but continue")
	showexec ("Wait 1 second", "sleep 1")
	showexec ("Noexist command but quit", "noexist but quit", 1)
	showexec ("Never exec", "/bin/ls")
	
# Main program
#-----------------------------------------------------------------------------

if __name__ == "__main__":
	init()
	main(sys.argv[1:])
	exit()
