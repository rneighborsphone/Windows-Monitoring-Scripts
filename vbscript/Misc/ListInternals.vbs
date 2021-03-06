Option Explicit
dim apiKey, secretKey, objHTTP, url, resp, token, tag
dim oAgents, oAgent, oWMI, oRes, oEntry, IDs, pos, oAgentInfo, oInfo, cfgfile, oConf, oFso

tag = WScript.arguments.named.item("tag")

cfgfile = left(Wscript.ScriptFullName,InStrRev(Wscript.ScriptFullName, "\")) + "config.xml"
Set oConf = CreateObject("Microsoft.XMLDOM")
oConf.async = False
Set oFso = CreateObject("Scripting.FileSystemObject")
if oFso.FileExists(cfgfile) then
  oConf.Load(cfgfile)
else
  oConf.LoadXML("<monitis><APIKey/><SecretKey/></monitis>")
end if

apiKey = oConf.documentElement.selectSingleNode("APIKey").text
secretKey = oConf.documentElement.selectSingleNode("SecretKey").text

if apiKey = "" then
  wscript.echo "APIKey not configured"
  wscript.quit
end if

if secretKey = "" then
  wscript.echo "SecretKey not configured"
  wscript.quit
end if

'Initialize HTTP connection object
Set objHTTP = CreateObject("Microsoft.XMLHTTP")

'Request a token to use in following calls
url = "http://www.monitis.com/api?action=authToken&apikey=" + apiKey + "&secretkey=" + secretKey
wscript.echo "Requesting token"
wscript.echo "GET: " + url
objHTTP.open "GET", url, False
objHTTP.send
resp = objHTTP.responseText
wscript.echo "Result: " + resp
pos = InStr(resp, ":") + 2
token = mid(resp, pos, len(resp) - pos - 1)

url = "http://www.monitis.com/api?action=agents&apikey=" + apiKey + "&output=xml"
objHTTP.open "GET", url, False
wscript.echo "Requesting agents list"
wscript.echo "GET: " + url
objHTTP.send

Set oAgents = CreateObject("Microsoft.XMLDOM")
oAgents.async = False
oAgents.LoadXML(objHTTP.responseText)

for each oAgent in oAgents.documentElement.childnodes
  wscript.echo "Agent ID: ", oAgent.selectSingleNode("id").text, oAgent.selectSingleNode("key").text
  
  url = "http://www.monitis.com/api?action=agentInfo&apikey=" + apiKey + "&output=xml&agentId=" + oAgent.selectSingleNode("id").text + "&loadTests=true"
  objHTTP.open "GET", url, False
  objHTTP.send

  Set oAgentInfo = CreateObject("Microsoft.XMLDOM")
  oAgentInfo.async = False
  oAgentInfo.LoadXML(objHTTP.responseText)
  
  for each oInfo in oAgentInfo.documentElement.childnodes
    ListNames oInfo.childnodes
  next
next

Sub ListNames(oNames)
  dim oName, IP, name, str, pos, pos1, computer
  for each oName in oNames
    if oName.NodeName <> "#text" then
	  if oName.selectSingleNode("ip") is nothing then IP = "" else IP = " IP: " + oName.selectSingleNode("ip").text 
	  
	  str = oName.selectSingleNode("name").text
	  pos = InStr(str, "@") -1
	  name = mid(str, 1, pos)
	  pos1 = InStr(pos + 2, str, "@") -1
	  computer = mid(str, pos+ 2, pos1 - pos -1)
	  wscript.echo "  " + name + " on " + computer + IP
	end if 
  next  
End Sub

Function FmtDate(dt)
  FmtDate = cstr(Datepart("yyyy", dt)) + "-" + right("0" + cstr(Datepart("m", dt)),2) + "-" +  right("0" + cstr(Datepart ("d", dt)),2) + " " + right("0" + cstr(Datepart("h", dt)),2) + ":" + right("0" + cstr(Datepart("n", dt)),2) + ":" + right("0" + cstr(Datepart("S", dt)),2)
end function

Function GMTDate()
  GMTDate = now
  Set oRes = oWMI.ExecQuery("Select LocalDateTime from Win32_OperatingSystem")
  For each oEntry in oRes
    GMTDate = DateAdd("n", -CInt(right(oEntry.LocalDateTime, 4)), GMTDate)
  next
End function
