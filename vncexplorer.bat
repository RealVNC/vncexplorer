@ECHO OFF

cls

:: Copyright (C) 2016 RealVNC Limited. All rights reserved.
::
:: Redistribution and use in source and binary forms, with or without
:: modification, are permitted provided that the following conditions are met:
:: 
:: 1. Redistributions of source code must retain the above copyright notice, this
:: list of conditions and the following disclaimer.
::
:: 2. Redistributions in binary form must reproduce the above copyright notice,
:: this list of conditions and the following disclaimer in the documentation
:: and/or other materials provided with the distribution.
:: 
:: 3. Neither the name of the copyright holder nor the names of its contributors
:: may be used to endorse or promote products derived from this software without
:: specific prior written permission.
:: 
:: THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
:: AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
:: IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
:: DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
:: FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
:: DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
:: SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
:: CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
:: OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
:: OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

echo This script is designed to gather system data to assist RealVNC Support
echo troubleshoot issues with RealVNC Server running on Microsoft Windows systems.
echo.
echo Data collected:
echo Currently running processes, current user environment, system IP address,
echo information, vnc registry keys (HKLM\SOFTWARE\RealVNC
echo and HKCU\SOFTWARE\RealVNC), and event log data for VNC Server.
echo.
echo Security information (including provate keys and chat history) is not collected.
echo.
echo Press enter to accept this and continue or press CTRL+C to terminate this script
pause

echo Administrative permissions required. Detecting permissions...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed.
) else (
    echo Failure: Current permissions inadequate. Please run this with elevated privileges
goto :quit
)

echo.
set VDIR="%cd%\result"
goto :runit

:runit
echo Writing output to %VDIR%

if not exist %VDIR% (
    MKDIR %VDIR%
)

echo Getting user environment
set > %VDIR%\userenv.txt

echo Getting network details
ipconfig /all > %VDIR%\ipconfig.txt

echo Querying services
:: query VNC Server service
2>nul sc qc vncserver > %VDIR%\vnc_service_status.txt

echo Getting running processes
:: get list of all running processes
2>nul tasklist /FO list > %VDIR%\all_running_processes.txt

echo Getting netstat
:: get netstat info
netstat -an > %VDIR%\netstat.txt

echo Checking firewall status
:: checking firewall status - netsh firewall is deprecated but this must work with older Windows OSs
netsh firewall show state > %VDIR%\firewall.txt

echo Getting registry keys - Server
:: query registry keys
:: Service Mode keys (HKLM)
echo Server : Parameters > %VDIR%\hklm-reg.txt
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver >> %VDIR%\hklm-reg.txt

echo Server : License >> %VDIR%\hklm-reg.txt
2>nul reg query HKLM\SOFTWARE\RealVNC  >> %VDIR%\hklm-reg.txt

echo Server : CompatibilityFlags >> %VDIR%\hklm-reg.txt
2>nul reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" | findstr "vnc.*.exe" >> %VDIR%\hklm-reg.txt

:: get computer policy
2>nul reg query HKLM\Software\Policies\RealVNC\vncserver > %VDIR%\vncserver-policy-computer.txt

:: User Mode keys (HKCU)
echo Server : Parameters > %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver >> %VDIR%\hkcu-reg.txt

echo Getting registry keys - Locale info (HKCU)
:: Locale settings
echo Server : Locale (Service Mode UI): >> %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserverui-service | findstr Locale >> %VDIR%\hkcu-reg.txt
echo Server : Locale (User Mode UI): >> %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserverui-user | findstr Locale >> %VDIR%\hkcu-reg.txt

:: get user policy
2>nul reg query HKCU\Software\Policies\RealVNC > %VDIR%\vncserver-policy-user.txt

:: Viewer Keys (HKCU)
echo Getting registry keys - Viewer
echo Viewer : Parameters > %VDIR%\hkcu-reg-viewer.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer >> %VDIR%\hkcu-reg-viewer.txt

:: vncconfig
echo VNCConfig >> %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncconfig >> %VDIR%\hkcu-reg.txt

:: vnclicense check/list
echo Gathering license keys
if exist "C:\Program Files\RealVNC\VNC Server\vnclicense.exe" (
    "C:\Program Files\RealVNC\VNC Server\vnclicense.exe" -list > %VDIR%\licensekeys.txt
)

::remove private keys
type %VDIR%\hklm-reg.txt | findstr /v RSA_Private_Key > %VDIR%\hklm-reg2.txt
type %VDIR%\hkcu-reg.txt | findstr /v RSA_Private_Key > %VDIR%\hkcu-reg2.txt
type %VDIR%\hkcu-reg-viewer.txt | findstr /v RSA_Private_Key > %VDIR%\hkcu-reg-viewer2.txt

move %VDIR%\hklm-reg2.txt %VDIR%\hklm-reg.txt >nul
move %VDIR%\hkcu-reg2.txt %VDIR%\hkcu-reg.txt >nul
move %VDIR%\hkcu-reg-viewer2.txt %VDIR%\hkcu-reg-viewer.txt >nul

echo Getting data from MSInfo32
if exist "c:\Program Files\Common Files\microsoft shared\MSInfo\msinfo32.exe" (
 "c:\Program Files\Common Files\microsoft shared\MSInfo\msinfo32.exe" /report %VDIR%\msinfo32_report.txt
) else (
  echo "Unable to find or execute msinfo32"
)

:: power report
echo Running system power report
mkdir %VDIR%\PowerReport
if exist "C:\Windows\System32\powercfg.exe" (
    "C:\Windows\System32\powercfg.exe" -energy >nul
    move energy-report.html %VDIR%\PowerReport >nul
)

:: log files
echo Gathering log files
mkdir %VDIR%\UserModeServerLogs
FOR %%i IN (%appdata%) DO IF EXIST %%~si\..\Local\RealVNC\vncserver.log copy %%~si\..\Local\RealVNC\vncserver.* %VDIR%\UserModeServerLogs\ >nul
mkdir %VDIR%\ServiceModeServerLogs
if exist "C:\Program Files\RealVNC\VNC Server\Logs\vncserver.log" copy "C:\Program Files\RealVNC\VNC Server\Logs"\* %VDIR%\ServiceModeServerLogs >nul
if exist "C:\ProgramData\RealVNC-Service\vncserver.log" copy "C:\ProgramData\RealVNC-Service"\* %VDIR%\ServiceModeServerLogs >nul
mkdir %VDIR%\ViewerLogs
FOR %%i IN (%appdata%) DO IF EXIST %%~si\..\Local\RealVNC\vncviewer.log copy %%~si\..\Local\RealVNC\vncviewer.* %VDIR%\ViewerLogs\ >nul

echo Complete!
echo Please send the contents of %VDIR% to RealVNC Support by
echo attaching the files to an email containing your ticket number in the subject line

:quit
echo Done
