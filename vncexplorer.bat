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
:: 


echo This script is designed to gather system data to assist RealVNC Support
echo troubleshoot issues with RealVNC Server running on Microsoft Windows systems.
echo.
echo Data collected: 
echo Currently running processes, current user environment, system IP address,
echo information, vnc registry keys (HKLM\SOFTWARE\RealVNC 
echo and HKCU\SOFTWARE\RealVNC), and event log data for VNC Server. 
echo.
echo Security information (including Private keys, passwords, known hosts) is not 
echo collected.
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
set /p VDIR=Please enter output directory: 
goto :runit

:runit
echo Writing output to %VDIR%

if not exist %VDIR% (
	MKDIR %VDIR%
)

echo Getting data from MSInfo32
if exist "c:\Program Files\Common Files\microsoft shared\MSInfo\msinfo32.exe" (
 "c:\Program Files\Common Files\microsoft shared\MSInfo\msinfo32.exe" /report %VDIR%\msinfo32_report.txt 
) else (
  echo "Unable to find or execute msinfo32"
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
echo Server License: > %VDIR%\hklm-reg.txt
2>nul reg query HKLM\SOFTWARE\RealVNC  >> %VDIR%\hklm-reg.txt
echo Server : Security types: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr SecurityTypes >> %VDIR%\hklm-reg.txt
echo Server : Encryption: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Encryption >> %VDIR%\hklm-reg.txt
echo Server : Auth Timeout: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr  AuthTimeout>> %VDIR%\hklm-reg.txt
echo Server : Authentication: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Authentication >> %VDIR%\hklm-reg.txt
echo Server : NtLogonAsInteractive: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr NtLogonAsInteractive >> %VDIR%\hklm-reg.txt
echo Server : Edition: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Edition >> %VDIR%\hklm-reg.txt
echo Server : AllowHTTP: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AllowHttp >> %VDIR%\hklm-reg.txt
echo Server : AllowRfb: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AllowRfb >> %VDIR%\hklm-reg.txt
echo Server : AlwaysShared: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AlwaysShared >> %VDIR%\hklm-reg.txt
echo Server : NeverShared: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr NeverShared >> %VDIR%\hklm-reg.txt
echo Server : DisableAero: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableAero >> %VDIR%\hklm-reg.txt
echo Server: DisableAddNewClient: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableAddNewClient >> %VDIR%\hklm-reg.txt
echo Server : DisableTrayIcon: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableTrayIcon >> %VDIR%\hklm-reg.txt
echo Server : DisableClose: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableClose >> %VDIR%\hklm-reg.txt
echo Server : DisableEffects: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableEffects >> %VDIR%\hklm-reg.txt
echo Server : DisableLocalInputs: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableLocalInputs >> %VDIR%\hklm-reg.txt
echo Server : DisconnectAction: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisconnectAction >> %VDIR%\hklm-reg.txt
echo Server : DisconnectClients: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisconnectClients >> %VDIR%\hklm-reg.txt
echo Server : EnableChat: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr EnableChat >> %VDIR%\hklm-reg.txt
echo Server : AcceptCutText: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AcceptCutText >> %VDIR%\hklm-reg.txt
echo Server : BlacklistThreshold: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr BlacklistThreshold >> %VDIR%\hklm-reg.txt
echo Server : BlacklistTimeout: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr BlacklistTimeout >> %VDIR%\hklm-reg.txt
echo Server : BlankScreen: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr BlankScreen >> %VDIR%\hklm-reg.txt
echo Server : HttpPort: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr HttpPort >> %VDIR%\hklm-reg.txt
echo Server : IdleTimeout: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr IdleTimeout >> %VDIR%\hklm-reg.txt
echo Server : KerberosPrincipleName: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr KerberosPrincipleName >> %VDIR%\hklm-reg.txt
echo Server : ServiceDiscoveryEnabled: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr ServiceDiscoveryEnabled >> %VDIR%\hklm-reg.txt
echo Server : Log: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Log >> %VDIR%\hklm-reg.txt
echo Server : RfbPort: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr RfbPort >> %VDIR%\hklm-reg.txt
echo Server : SendCutText: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr SendCutText >> %VDIR%\hklm-reg.txt
echo Server : UpdateMethod: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr UpdateMethod >> %VDIR%\hklm-reg.txt
echo Server : CaptureMethod: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr CaptureMethod >> %VDIR%\hklm-reg.txt
echo Server : UseCaptureBit: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr UseCaptureBit >> %VDIR%\hklm-reg.txt
echo Server : UserPasswdVerifier: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr UserPasswdVerifier >> %VDIR%\hklm-reg.txt
echo Server : Permissions : >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Permissions  >> %VDIR%\hklm-reg.txt
echo Server : ShareFiles : >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr ShareFiles  >> %VDIR%\hklm-reg.txt
echo Server : SimulateSAS : >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr SimulateSAS  >> %VDIR%\hklm-reg.txt
echo Server : localhost (bool) : >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr localhost  >> %VDIR%\hklm-reg.txt
echo Server : DisableOptions: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisableOptions >> %VDIR%\hklm-reg.txt
echo Server : DisplayDevice: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr DisplayDevice >> %VDIR%\hklm-reg.txt
echo Server : EnableAutoUpdateChecks: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr EnableAutoUpdateChecks >> %VDIR%\hklm-reg.txt
echo Server : UpdateCheckFrequencyDays: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr UpdateCheckFrequencyDays >> %VDIR%\hklm-reg.txt
echo Server : EnableManualUpdateChecks: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr EnableManualUpdateChecks >> %VDIR%\hklm-reg.txt
echo Server : TcpListenAddresses: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr TcpListenAddresses >> %VDIR%\hklm-reg.txt
echo Server : EnableGuestLogin: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr EnableGuestLogin >> %VDIR%\hklm-reg.txt
echo Server : GuestAccess: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr GuestAccess >> %VDIR%\hklm-reg.txt
echo Server : EnableRemotePrinting: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr EnableRemotePrinting >> %VDIR%\hklm-reg.txt
echo Server : AcceptKeyEvents: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AcceptKeyEvents >> %VDIR%\hklm-reg.txt
echo Server : AcceptPointerEvents: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AcceptPointerEvents >> %VDIR%\hklm-reg.txt
echo Server : AllowChangeDefaultPrinter: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AllowChangeDefaultPrinter >> %VDIR%\hklm-reg.txt
echo Server : LogDir: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr LogDir >> %VDIR%\hklm-reg.txt
echo Server : LogFile: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr LogFile >> %VDIR%\hklm-reg.txt
echo Server : ConnNotifyTimeout: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr ConnNotifyTimeout >> %VDIR%\hklm-reg.txt
echo Server : ConnTimeout: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr ConnTimeout >> %VDIR%\hklm-reg.txt
echo Server : UseCaptureBlt: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr UseCaptureBlt >> %VDIR%\hklm-reg.txt
echo Server : Desktop: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Desktop >> %VDIR%\hklm-reg.txt
echo Server : QueryConnect: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncvserver | findstr QueryConnect >> %VDIR%\hklm-reg.txt
echo Server : QueryOnlyIfLoggedOn: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr QueryOnlyIfLoggedOn >> %VDIR%\hklm-reg.txt
echo Server : QueryConnectTimeout: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr QueryConnectTimeout >> %VDIR%\hklm-reg.txt
echo Server : QueryTimeoutRights: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr QueryTimeoutRights >> %VDIR%\hklm-reg.txt
echo Server : QuitOnCloseStatusDialog: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr QuitOnCloseStatusDialog >> %VDIR%\hklm-reg.txt
echo Server : RemovePattern: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr RemovePattern >> %VDIR%\hklm-reg.txt
echo Server : RemoveWallpaper: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr RemoveWallpaper >> %VDIR%\hklm-reg.txt
echo Server : AgentArgs: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr _ServerBlackScreenWorkAround >> %VDIR%\hklm-reg.txt
echo Server : AllowCloudRfb: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr AllowCloudRfb >> %VDIR%\hklm-reg.txt
echo Server : CloudCredentialsFile: >> %VDIR%\hklm-reg.txt 
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr CloudCredentialsFile >> %VDIR%\hklm-reg.txt

:: get computer policy
2>nul reg export HKLM\Software\Policies\RealVNC\vncserver %VDIR%\vncserver-policy-computer.txt

:: get user polocy
2>nul reg export HKCU\Software\Policies\RealVNC %VDIR%\vncserver-policy-user.txt

echo Server : CompatibilityFlags : >> %VDIR%\hklm-reg.txt 
2>nul reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" | findstr "vnc.*.exe" >> %VDIR%\hklm-reg.txt

echo Getting registry keys - Locale info (HKCU)
:: Locale settings
echo Server : Locale (Service Mode UI): >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserverui-service | findstr Locale >> %VDIR%\hkcu-reg.txt
echo Server : Locale (User Mode UI): >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserverui-user | findstr Locale >> %VDIR%\hkcu-reg.txt
echo Server: Local (Service ModeServer Transmitted Messages)
2>nul reg query HKLM\SOFTWARE\RealVNC\vncserver | findstr Locale >> %VDIR%\hklm-reg.txt
echo Server : Locale (User Mode Server Transmitted Messages: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Locale >> %VDIR%\hkcu-reg.txt
 
 
:: Viewer Keys (HKCU)
echo Getting registry keys - Viewer
echo Viewer : Encryption Setting: > %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr Encryption >> %VDIR%\hkcu-reg.txt
echo Viewer : AutoSelect: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr AutoSelect >> %VDIR%\hkcu-reg.txt
echo Viewer : ClientCutText: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr ClientCutText >> %VDIR%\hkcu-reg.txt
echo Viewer : Scaling: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr Scaling >> %VDIR%\hkcu-reg.txt
echo Viewer : SendKeyEvents: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr SendKeyEvents >> %VDIR%\hkcu-reg.txt
echo Viewer : SendPointerEvents: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr SendPointerEvents >> %VDIR%\hkcu-reg.txt
echo Viewer : ServerCutText: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr ServerCutText >> %VDIR%\hkcu-reg.txt
echo Viewer : ShareFiles: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr ShareFiles >> %VDIR%\hkcu-reg.txt
echo Viewer : Monitor: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr Monitor >> %VDIR%\hkcu-reg.txt
echo Viewer : PreferredEncoding: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr PreferredEncoding >> %VDIR%\hkcu-reg.txt
echo Viewer : ProtocolVersion: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr ProtocolVersion >> %VDIR%\hkcu-reg.txt
echo Viewer : Shared: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr Shared >> %VDIR%\hkcu-reg.txt
echo Viewer : SendMediaKeys: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr SendMediaKeys >> %VDIR%\hkcu-reg.txt
echo Viewer : KeepAliveInterval: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr KeepAliveInterval >> %VDIR%\hkcu-reg.txt
echo Viewer : KeepAliveResponseTimeout: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr KeepAliveResponseTimeout >> %VDIR%\hkcu-reg.txt
:: viewer keys for VNC Connect
echo Viewer : EnableAnalytics: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr EnableAnalytics >> %VDIR%\hkcu-reg.txt
echo Viewer : HideScreenshots: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr HideScreenshots >> %VDIR%\hkcu-reg.txt
echo Viewer : PasswordStore: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr PasswordStore >> %VDIR%\hkcu-reg.txt
echo Viewer : PasswordStoreOffer: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr PasswordStoreOffer >> %VDIR%\hkcu-reg.txt
echo Viewer : Quality: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr Quality >> %VDIR%\hkcu-reg.txt
echo Viewer : UpdateScreenshot: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncviewer | findstr UpdateScreenshot >> %VDIR%\hkcu-reg.txt


:: User Mode keys (HKCU)
echo User Mode Server : security types: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr SecurityTypes >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Encryption: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Encryption >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Authentication: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Authentication >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Auth Timeout: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AuthTimeout >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Edition: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Edition >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AllowHTTP: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AllowHttp >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AllowRfb: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AllowTcpListenRfb >> %VDIR%\hkcu-reg.txt
echo User Mode Server : TcpListenAddresses: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr TcpListenAddresses >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AllowTcpListenRfb: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AllowRfb >> %VDIR%\hkcu-reg.txt
echo User Mode Server : DisableAero: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr DisableAero >> %VDIR%\hkcu-reg.txt
echo User Mode Server : DisableOptions: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr DisableOptions >> %VDIR%\hkcu-reg.txt
echo User Mode Server: DisableAddNewClient: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr DisableAddNewClient >> %VDIR%\hkcu-reg.txt
echo User Mode Server : DisableTrayIcon: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr DisableTrayIcon >> %VDIR%\hkcu-reg.txt
echo User Mode Server : DisplayDevice: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr DisplayDevice >> %VDIR%\hkcu-reg.txt
echo User Mode Server : EnableAutoUpdateChecks: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr EnableAutoUpdateChecks >> %VDIR%\hkcu-reg.txt
echo User Mode Server : UpdateCheckFrequencyDays: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr UpdateCheckFrequencyDays >> %VDIR%\hkcu-reg.txt
echo User Mode Server : EnableManualUpdateChecks: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr EnableManualUpdateChecks >> %VDIR%\hkcu-reg.txt
echo User Mode Server : EnableChat: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr EnableChat >> %VDIR%\hkcu-reg.txt
echo User Mode Server : EnableGuestLogin: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr EnableGuestLogin >> %VDIR%\hkcu-reg.txt
echo User Mode Server : GuestAccess: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr GuestAccess >> %VDIR%\hkcu-reg.txt
echo User Mode Server : EnableRemotePrinting: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr EnableRemotePrinting >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AcceptCutText: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AcceptCutText >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AcceptKeyEvents: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AcceptKeyEvents >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AcceptPointerEvents: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AcceptPointerEvents >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AllowChangeDefaultPrinter: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AllowChangeDefaultPrinter >> %VDIR%\hkcu-reg.txt
echo User Mode Server : BlacklistThreshold: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr BlacklistThreshold >> %VDIR%\hkcu-reg.txt
echo User Mode Server : BlacklistTimeout: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr BlacklistTimeout >> %VDIR%\hkcu-reg.txt
echo User Mode Server : HttpPort: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr HttpPort >> %VDIR%\hkcu-reg.txt
echo User Mode Server : IdleTimeout: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr IdleTimeout >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Log: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Log >> %VDIR%\hkcu-reg.txt
echo User Mode Server : LogDir: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr LogDir >> %VDIR%\hkcu-reg.txt
echo User Mode Server : LogFile: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr LogFile >> %VDIR%\hkcu-reg.txt
echo User Mode Server : RfbPort: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr RfbPort >> %VDIR%\hkcu-reg.txt
echo User Mode Server : SendCutText: >> %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr SendCutText >> %VDIR%\hkcu-reg.txt
echo User Mode Server : UpdateMethod: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr UpdateMethod >> %VDIR%\hkcu-reg.txt
echo User Mode Server : ConnNotifyTimeout: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr ConnNotifyTimeout >> %VDIR%\hkcu-reg.txt
echo User Mode Server : ConnTimeout: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr ConnTimeout >> %VDIR%\hkcu-reg.txt
echo User Mode Server : UseCaptureBlt: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr UseCaptureBlt >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Desktop: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Desktop >> %VDIR%\hkcu-reg.txt
echo User Mode Server : UserPasswdVerifier: >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr UserPasswdVerifier >> %VDIR%\hkcu-reg.txt
echo User Mode Server : Permissions : >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr Permissions  >> %VDIR%\hkcu-reg.txt
echo User Mode Server : CompatibilityFlags : >> %VDIR%\hkcu-reg.txt 
2>nul reg query "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers" | findstr "vnc.*.exe"   >> %VDIR%\hkcu-reg.txt
echo User Mode Server : AllowCloudRfb: >> %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr AllowCloudRfb >> %VDIR%\hkcu-reg.txt
echo User Mode Server : CloudCredentialsFile: >> %VDIR%\hkcu-reg.txt
2>nul reg query HKCU\SOFTWARE\RealVNC\vncserver | findstr CloudCredentialsFile >> %VDIR%\hkcu-reg.txt

:: vncconfig
echo VNCConfig >> %VDIR%\hkcu-reg.txt 
2>nul reg query HKCU\SOFTWARE\RealVNC\vncconfig >> %VDIR%\hkcu-reg.txt

:: vnclicense check/list
echo Gathering license keys
if exist "C:\Program Files\RealVNC\VNC Server\vnclicense.exe" (
	"C:\Program Files\RealVNC\VNC Server\vnclicense.exe" -list > %VDIR%\licensekeys.txt
)

:: power report 
mkdir %VDIR%\PowerReport
powercfg -energy
copy energy-report.html %VDIR%\PowerReport

:: log files
echo Gathering log files
mkdir %VDIR%\UserModeServerLogs
FOR %%i IN (%appdata%) DO IF EXIST %%~si\..\Local\RealVNC\vncserver.log copy %%~si\..\Local\RealVNC\vncserver.* %VDIR%\UserModeServerLogs\
mkdir %VDIR%\ServiceModeServerLogs
if exist "C:\Program Files\RealVNC\VNC Server\Logs\vncserver.log" copy "C:\Program Files\RealVNC\VNC Server\Logs"\* %VDIR%\ServiceModeServerLogs
mkdir %VDIR%\ViewerLogs
FOR %%i IN (%appdata%) DO IF EXIST %%~si\..\Local\RealVNC\vncviewer.log copy %%~si\..\Local\RealVNC\vncviewer.* %VDIR%\ViewerLogs\

:: event logs
echo Running Script to export event logs
mkdir %VDIR%\EventLogs
cscript .\vncexporteventlog.vbs %VDIR%\EventLogs

echo Complete!
echo Please send the contents of %VDIR% to RealVNC Support by 
echo attaching the files to an email containing
echo your ticket number in the subject line

:quit
echo Done
