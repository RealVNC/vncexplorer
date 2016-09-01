'Script Name : ExportEventLogs.vbs
' Export VNC related log events from Application and System log
' Copyright (C) 2016 RealVNC Limited. All rights reserved.

' Redistribution and use in source and binary forms, with or without
' modification, are permitted provided that the following conditions are met:
' 
' 1. Redistributions of source code must retain the above copyright notice, this
' list of conditions and the following disclaimer.
'
' 2. Redistributions in binary form must reproduce the above copyright notice,
' this list of conditions and the following disclaimer in the documentation
' and/or other materials provided with the distribution.
' 
' 3. Neither the name of the copyright holder nor the names of its contributors
' may be used to endorse or promote products derived from this software without
' specific prior written permission.
' 
' THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
' IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
' DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
' FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
' DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
' SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
' CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
' OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
' OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
' 

Option Explicit
Const ForReading   = 1
Const ForWriting   = 2
Const ForAppending = 8
Dim objFSO, wshShell, wshNetwork, strComputer, objWMIService, colLoggedEvents, objEvent, strPath, strOutputFile, objOutFile, strDate, strTime, log, i, args
Dim arrLogs(1)

On Error Resume Next

Set objFSO        = CreateObject("Scripting.FileSystemObject")
Set wshShell      = CreateObject("Wscript.Shell")

'strPath = objFSO.GetFile(Wscript.ScriptFullName).ParentFolder.Path
Set args = WScript.Arguments
strPath = args.Item(0)
strOutputfile = strPath & "\VNCServereventlogs.txt"
set objOutFile = objFSO.CreateTextFile(strOutputFile, True)
arrLogs(0) = "Application"
arrLogs(1) = "System"  
   
If Err.Number <> 0 Then
   Wscript.Quit
End If

'Attempt to connect to WMI, quit script on failure
strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" _
    & strComputer & "\root\cimv2")

If Err.Number <> 0 Then
	wscript.quit
End If


'loop through predefined logs and return events with a source 'VNC Server'
For i = 0 to UBound(arrLogs)
	
	'Get log Events 
	Set colLoggedEvents = objWMIService.ExecQuery _
		("Select * from Win32_NTLogEvent " _
			& "Where Logfile ='" & arrLogs(i) & "' " _
			& "AND SourceName = 'VNC Server'")

	'Check if results have been returned and write output if necessary	
	If colLoggedEvents.Count > 0 Then
		objOutFile.WriteLine "------------------------VNC Server Events - " & arrLogs(i) & " log----------------------------"
		objOutFile.WriteLine "Date: " & Now
		objOutFile.WriteLine "----------------------------------------------------------------------------"
		objOutFile.Writeline vbCrlf
		objOutFile.WriteLine "DateTime,Category,ComputerName,Event Code,Source Name,Event Type,User,Message"
	
		For Each objEvent in colLoggedEvents
    
			strDate = WMIDateStringToDate (objEvent.TimeWritten)
	
			objOutFile.WriteLine strDate & "," _
			& objEvent.Category & "," _
			& objEvent.ComputerName & "," _
			& objEvent.EventCode & "," _
			& objEvent.SourceName & "," _
			& objEvent.Type & "," _
			& objEvent.User & "," _
			& objEvent.Message
		Next
	End If
Next

objOutFile.Close
set objOutFile 	  = nothing
Set objFSO        = nothing
Set wshShell      = nothing


Function WMIDateStringToDate(dtmInstallDate)
'converts universal date format to uk date and time
    WMIDateStringToDate = _
        CDate(Mid(dtmInstallDate, 5, 2) &_
        "/" &_
        Mid(dtmInstallDate, 7, 2) &_
        "/" &_
        Left(dtmInstallDate, 4) &_
        " " &_
        Mid (dtmInstallDate, 9, 2) &_
        ":" &_
        Mid(dtmInstallDate, 11, 2) &_
        ":" &_
        Mid(dtmInstallDate, 13, 2))
End Function