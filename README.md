# VNCExplorer
VNCExplorer is a set of scripts that can be run on supported platforms to gather configuration information on RealVNC software - and
 the relevant configuration of the customer system - to help RealVNC Support diagnose and resolve customer support tickets more efficiently.
 


## Installing / Getting started
The latest release is available at: https://github.com/andrewwoodhouse/vncexplorer/releases/latest
 
Simply extract the ZIP or tar.gz file from the link above and run with administrative priveleges on your system.

Platform specific details below:

### AIX/Solaris/HPUX/Linux/OSX
#### Data collected
The contents of /etc/vnc, /etc/pam.d, contents of user .vnc directory, currently running VNC processes, current user environment, X11 configuration information, 
system IP addresses, installed VNC packages, system hardware details, vnc license information 
Private keys and chat history are NOT included


#### Using (AIX/Solaris/HPUX/Linux/OSX)

Once downloaded and extracted onto the relevant system, please make this script executable by running in a terminal: chmod u+x
This script must be run either as root or via sudo.
To run the script using sudo, type: sudo ./vncexplorer.sh

The script will gather information about the system it's running on and will create a temporary working directory called {hostname} in the current working directory.  The script will prompt for a non-root username. This should be the username used if you run RealVNC Server usermode or virtual mode server. 
The script will default to root if you don't enter anything.

Once finished, it will create a tar file in /var/tmp/vncexplorer. The name of this file is vncsupport-{hostname}.tar

The script will clear up after itself - but please remove /var/tmp/vncexplorer once the file has been submitted to RealVNC Support.

 
### Windows
#### Data collected
Currently running processes, current user environment, IP addresses, network connection status, VNC registry keys 
(HKLM/Software/RealVNC and HKCU/Software/RealVNC), VNC service status, Event log data for VNC Server
Secure information (private keys, passwords, chat history) is not collected.

#### Using (Windows)

Once downloaded and extracted onto the relevant system, please excute the batch file (vncexplorer.bat) in an elevated command prompt.

The script will prompt for a directory to write the output to. Once finished, please zip the contents of the output directory specified and send this zip file to RealVNC Support.

 

# Contributing

If you'd like to make changes or contribute, please fork the repository and use a feature
branch. Pull requests are welcome.


# Licensing


Copyright (C) 2016 RealVNC Limited. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
