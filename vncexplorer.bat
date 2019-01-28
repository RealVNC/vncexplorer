@ECHO OFF

cls

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

set ENT=0
set CONFEXISTS=0

:: enable debug logging
2>nul reg query HKLM\Software\RealVNC /v vncserver_license >nul
if %ERRORLEVEL% EQU 0 (
    set ENT=1)
    setlocal enabledelayedexpansion
    if %ENT% EQU 1 (
        2>nul reg query HKLM\Software\Policies\RealVNC\vncserver >nul
        if !ERRORLEVEL! EQU 0 (
            set CONFEXISTS=1
            2>nul reg save HKLM\Software\Policies\RealVNC\vncserver vncserver.key /y >nul
            2>nul reg add HKLM\Software\Policies\RealVNC\vncserver /v Log /t REG_SZ /d "*:file:100" /f >nul
        ) else (
            2>nul reg add HKLM\Software\Policies\RealVNC\vncserver /v Log /t REG_SZ /d "*:file:100" /f >nul
    )
) else (
    2>nul reg query HKLM\Software\RealVNC\vncserver >nul
    if !ERRORLEVEL! EQU 0 (
        set CONFEXISTS=1
        2>nul reg save HKLM\Software\RealVNC\vncserver vncserver.key /y >nul
        2>nul reg add HKLM\Software\RealVNC\vncserver /v Log /t REG_SZ /d "*:file:100" /f >nul
    ) else (
        2>nul reg add HKLM\Software\RealVNC\vncserver /v Log /t REG_SZ /d "*:file:100" /f >nul
    )
)

:again
set /p answer=VNC Server needs to restart apply debug logging. All existing connections to VNC Server will be interrupted. Is this OK? (Y / N)?
if /i "%answer:~,1%" EQU "Y" goto restartserver
if /i "%answer:~,1%" EQU "N" goto again
cho Input not valid, please try again or press Ctrl+C to exit script
goto again

:restartserver


:again2
set /p answer=Have you re-created the issue? (Y / N)?
if /i "%answer:~,1%" EQU "Y" goto gatherlogs
if /i "%answer:~,1%" EQU "N" goto again2
echo Input not valid, please try again or press Ctrl+C to exit script
goto again2

:gatherlogs

:: log files
echo Gathering log files
mkdir %VDIR%\UserModeServerLogs
FOR %%i IN (%appdata%) DO IF EXIST %%~si\..\Local\RealVNC\vncserver.log copy %%~si\..\Local\RealVNC\vncserver.* %VDIR%\UserModeServerLogs\ >nul
mkdir %VDIR%\ServiceModeServerLogs
if exist "C:\Program Files\RealVNC\VNC Server\Logs\vncserver.log" copy "C:\Program Files\RealVNC\VNC Server\Logs"\* %VDIR%\ServiceModeServerLogs >nul
if exist "C:\ProgramData\RealVNC-Service\vncserver.log" copy "C:\ProgramData\RealVNC-Service"\* %VDIR%\ServiceModeServerLogs >nul
mkdir %VDIR%\ViewerLogs
FOR %%i IN (%appdata%) DO IF EXIST %%~si\..\Local\RealVNC\vncviewer.log copy %%~si\..\Local\RealVNC\vncviewer.* %VDIR%\ViewerLogs\ >nul

::Gather events from EventLog
if exist "C:\Windows\System32\wevtutil.exe" (
    2>nul wevtutil qe Application /q:"*[System[Provider[@Name='VNC Server']]]" /rd:true /f:text > %VDIR%\EventLogServiceMode.txt"
) else (
    mkdir %VDIR%\EventLogs
    2>nul cscript .\vncexporteventlog.vbs %VDIR%\EventLogs
)

if %CONFEXISTS% EQU 1 (
    if %ENT% EQU 1 (
        2>nul reg restore HKLM\Software\Policies\RealVNC\vncserver vncserver.key >nul
    ) else (
        2>nul reg restore HKLM\Software\RealVNC\vncserver vncserver.key >nul
    )
) else (
    if %ENT% EQU 1 (
        2>nul reg delete HKLM\Software\Policies\RealVNC\vncserver /f >nul
    ) else (
        2>nul reg delete HKLM\Software\RealVNC\vncserver /f >nul
    )
)

2>nul del vncserver.key >nul

echo Getting user environment
set > %VDIR%\userenv.txt

echo Getting network details
ipconfig /all > %VDIR%\ipconfig.txt

:: query VNC Server service
echo Querying services
2>nul sc qc vncserver > %VDIR%\vnc_service_status.txt

:: get list of all running processes
echo Getting running processes
2>nul tasklist /FO list > %VDIR%\all_running_processes.txt

:: get netstat info
echo Getting netstat
netstat -an > %VDIR%\netstat.txt

:: checking firewall status - netsh firewall is deprecated but this must work with older Windows OSs
echo Checking firewall status
netsh firewall show state > %VDIR%\firewall.txt

:: query registry keys
:: Service Mode keys (HKLM)
echo Getting registry keys - Server
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

:: Locale settings
echo Getting registry keys - Locale info (HKCU)
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

:: dxdiag output
echo Getting data from dxdiag
if exist "C:\Windows\System32\dxdiag.exe" (
    "C:\Windows\System32\dxdiag.exe" /whql:off /t %VDIR%\dxdiag.txt >nul
) else (
    echo Unable to find or execute dxdiag
)

echo Getting data from MSInfo32
if exist "c:\Program Files\Common Files\microsoft shared\MSInfo\msinfo32.exe" (
    "c:\Program Files\Common Files\microsoft shared\MSInfo\msinfo32.exe" /report %VDIR%\msinfo32_report.txt
) else (
    echo Unable to find or execute msinfo32
)

:: power report
echo Running system power report - this will take at least 60 seconds
mkdir %VDIR%\PowerReport
if exist "C:\Windows\System32\powercfg.exe" (
    "C:\Windows\System32\powercfg.exe" -energy >nul
    move energy-report.html %VDIR%\PowerReport >nul
)

echo Complete!
echo Please send the contents of %VDIR% to RealVNC Support by
echo attaching the files to an email containing your ticket number in the subject line

:quit
echo Done
