#!/bin/sh

# Copyright (C) 2018 RealVNC Limited. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its contributors
# may be used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# this script can be used to collect information on VNC 5.x and 6.x
set -e

#set standard UNIX paths in case these are not set
ORIGPATH=$PATH
PATH=$PATH:/bin:/sbin:/usr/sbin:/usr/bin:/usr/ucb

Platform_Detection () {
PLATFORM="NONE"
if [ `uname -a | grep Linux | wc -l` -ge 1 ]; then PLATFORM="Linux";
elif [ `uname -a | grep AIX | wc -l` -ge 1 ]; then PLATFORM="AIX";
elif [ `uname -a | grep HP-UX | wc -l` -ge 1 ]; then PLATFORM="HPUX";
elif [ `uname -a | grep SunOS | wc -l` -ge 1 ]; then PLATFORM="SOLARIS";
elif [ `uname -a | grep Darwin | wc -l` -ge 1 ]; then PLATFORM="OSX"; fi
echo $PLATFORM
}

System_Check () {
	# basically is this a chkconfig system (RHEL/CentOS), a systemd system or an init system
	# ordering is important as some systems such as CentOS support both systemd and chkconfig for
	# compatibility purposes. Therefore we start with the oldest with systemd being final check
	if type initctl list > /dev/null 2>&1; then SYSTEMD=0; INITD=1; CHKCONFIG=0; fi
	if type chkconfig > /dev/null 2>&1; then SYSTEMD=0; INITD=0; CHKCONFIG=1; fi
	if type systemctl > /dev/null 2>&1; then SYSTEMD=1; INITD=0; CHKCONFIG=0; else SYSTEMD=0; INITD=0; CHKCONFIG=0; fi 

	# echo "type: systemd: $SYSTEMD chkconfig: $CHKCONFIG init: $INITD"
	# on some systems, initctl doesn't exist but it is still init based. Handle this:
	if [ "${SYSTEMD}" = "0" ] && [ "${INITD}" = "0" ] && [ "${CHKCONFIG}" = "0" ] ; then INITD=1; fi
	# we need to work out if we're running on Ubuntu 14.04 as we have a special case for that: 
	LSBRELEASE=`lsb_release -r | awk '{print $2}'`
	if [ "${LSBRELEASE}" = "14.04" ] && [ -d /usr/lib/systemd ]; then SYSTEMD=0; INITD=1; CHKCONFIG=0; fi
}

Repeated_Prompt () {
	echo "$1"
	RECREATED="N"
	while [ "$RECREATED" != "Y" ] ; do
		read ANS
		case "$ANS" in
		"y"|"Y"|"YES"|"yes"|"Yes") echo "Script will now continue";RECREATED="Y";;
		"n"|"N"|"NO"|"No") echo "$1";;
		*) echo "Input not valid, please try again or press Ctrl+C to exit script";;
		esac
	done
}

# platform detection
MYPLATFORM=`Platform_Detection`
echo "Platform: ${MYPLATFORM}"

# upstart detection
SYSTEMD=0
INITD=0
CHKCONFIG=0

if [ "${MYPLATFORM}" = "Linux" ]; then
	System_Check
fi

# check we are running with sufficient permissions
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; then
	if [ `id -u` -ne 0 ]; then echo "Please run as root (or using sudo)"; exit; fi
fi
if [ "${MYPLATFORM}" = "SOLARIS" ]; then
	if [ `/usr/bin/id | cut -d= -f2 | cut -d\( -f1` -ne 0 ]; then echo "Please run as root"; exit; fi
fi

# message output
set +e
echo "This script is designed to gather system data to assist RealVNC Support"
echo "troubleshoot issues with RealVNC Server running on UNIX / Linux systems."
echo ""
echo "Data collected:"
echo "The contents of /.vnc, /etc/vnc, /etc/pam.d, current user .vnc directory,"
echo "currently running processes, current user environment, system IP address"
echo "information, system hardware details and vnc license information."
echo "Private keys and chat history are NOT included"
echo "Press enter to accept this and continue or press CTRL+C to cancel"
read accept
set -e

# set initial variables
STARTDIR=`pwd`
CURRUSER=`whoami`

SERVICEMODE=0

# prompt for username to collect $HOME/.vnc 
echo "Are you diagnosing an issue with Service Mode (Y / N)?"
echo "(If unsure, RealVNC Support will advise as required)"
read ANS
case $ANS in
"y"|"Y"|"YES"|"yes"|"Yes") echo "assuming root user for service mode"; REALUSER="root"; SERVICEMODE=1;;
"n"|"N"|"NO"|"No") echo "Enter non-root username (relevant only for user and/or virtual mode servers)"; read USERENTERED; REALUSER=${USERENTERED};;
*) echo "Input not valid - assuming root"; REALUSER="root";;
esac

echo "collecting details for: $REALUSER"
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; then
	RCUHOMED=`cat /etc/passwd | grep \^$REALUSER\: | cut -d":" -f6`; else RCUHOMED=$HOME
	if [ ! $RCUHOMED ]; then echo "user $REALUSER home directory not found - assuming  /tmp"; RCUHOMED=/tmp; fi # if we can't get the user home directory, set it to /tmp so we don't throw errors
fi

if [ "${MYPLATFORM}" = "OSX" ]; then
	RCUHOMED="/Users/$REALUSER"
	echo "RCUHOMED: $RCUHOMED"
	if [ -z ${RCUHOMED} ]; then echo "cannot determine non-root user home directory. Aborting..."; exit; fi
fi

echo "Running from: ${STARTDIR} as user: ${CURRUSER}"
HOSTNAME=`hostname`
echo "HOSTNAME: ${HOSTNAME}"
TEMPDIR=/var/tmp/vncexplorer

if [ ! -d ${TEMPDIR} ]; then mkdir -p $TEMPDIR; fi

# identify if SELinux is installed on the machine
SELINUX=0
if type sestatus > /dev/null 2>&1; then SELINUX=1; fi
if [ "${SELINUX}" = "1" ]; then echo "SELinux Present"; fi

# clean old data
if [ -f ${TEMPDIR}/vncsupport-${HOSTNAME}.tar.gz ]; then
	echo "removing old vncexplorer data"
	rm ${TEMPDIR}/vncsupport-${HOSTNAME}.tar.gz
fi

# ensure STARTDIR and HOSTNAME are not empty
if [ -z ${STARTDIR} ]; then echo "Environment error encountered (output directory could not be created /tmp). Aborting..."; exit ; fi
if [ -z ${HOSTNAME} ]; then echo "Environment error encountered (no hostname found). Aborting..."; exit ; fi

# warn user that this exists - do they want to remove or keep?
if [ -d ${STARTDIR}/${HOSTNAME} ]; then echo "$STARTDIR/$HOSTNAME exists - CTRL+C to cancel this script or enter to continue (${STARTDIR}/${HOSTNAME} will be deleted)"; read accept2; fi
if [ -d ${STARTDIR}/${HOSTNAME} ]; then rm -rf ${STARTDIR}/${HOSTNAME}; fi

# create initial directory structure
set +e
mkdir ${STARTDIR}/${HOSTNAME}
mkdir ${STARTDIR}/${HOSTNAME}/etc
mkdir ${STARTDIR}/${HOSTNAME}/etc/vnc
mkdir ${STARTDIR}/${HOSTNAME}/etc/pam.d
mkdir ${STARTDIR}/${HOSTNAME}/etc/X11
mkdir ${STARTDIR}/${HOSTNAME}/userdotvnc
mkdir ${STARTDIR}/${HOSTNAME}/rootdotvnc
mkdir ${STARTDIR}/${HOSTNAME}/rootdotvnc/config.d
mkdir ${STARTDIR}/${HOSTNAME}/systemdotvnc
mkdir ${STARTDIR}/${HOSTNAME}/systemstate
mkdir ${STARTDIR}/${HOSTNAME}/filesystem
mkdir ${STARTDIR}/${HOSTNAME}/logs
mkdir ${STARTDIR}/${HOSTNAME}/logs/user
mkdir ${STARTDIR}/${HOSTNAME}/logs/system
mkdir ${STARTDIR}/${HOSTNAME}/startup

POLICYEXISTS=0
EXISTINGLOG=""

if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" ]; then
	#enable debug logging
	mkdir -p /etc/vnc/policy.d
	if [ -f /etc/vnc/policy.d/common ] ; then
		POLICYEXISTS=1
		if grep -q "Log=" /etc/vnc/policy.d/common ; then
			EXISTINGLOG=`grep "Log=" /etc/vnc/policy.d/common`
			sed -i '' 's/^Log=.*/Log=*:file:100/g' /etc/vnc/policy.d/common
		else
			echo "Log=*:file:100" >> /etc/vnc/policy.d/common
		fi
	else
		echo "Log=*:file:100" >> /etc/vnc/policy.d/common
	fi
fi

# restart service mode vncserver
if [ "${SERVICEMODE}" = "1" ]; then	
	# check user is happy for us to restart VNC Server
	Repeated_Prompt "VNC Server needs to restart apply debug logging. Is this OK? (Y / N) All existing connections to VNC Server will be interrupted."
	
	if [ "${MYPLATFORM}" = "Linux" ]; then
		if [ "${SYSTEMD}" = "1" ]; then
			systemctl restart vncserver-x11-serviced
		else
			/etc/init.d/vncserver-x11-serviced restart
		fi
	fi
	if [ "${MYPLATFORM}" = "AIX" ]; then
		: #to-do
	fi
	if [ "${MYPLATFORM}" = "HPUX" ]; then
		: #to-do
	fi
	if [ "${MYPLATFORM}" = "SOLARIS" ]; then
		: #to-do
	fi
	if [ "${MYPLATFORM}" = "OSX" ]; then
		/Library/vnc/vncserver -service -stop
		/Applications/RealVNC/VNC\ Server.app/Contents/MacOS/vncserver_service
	fi
else
	#test if Virtual Mode daemon is running
	if [ "${MYPLATFORM}" = "Linux" ]; then
		if ps -eF | grep -q "[v]ncserver-virtuald" ; then
			if [ "${SYSTEMD}" = "1" ]; then
					systemctl restart vncserver-virtuald
				else
					/etc/init.d/vncserver-virtuald restart
			fi
		fi
	fi
fi

sleep 2

echo "Please re-create the issue that you have reported to RealVNC Support"
sleep 2

Repeated_Prompt "Have you re-created the issue? (Y / N)?"

# copy relevant system /etc VNC configuration files
if [ -d /etc/vnc ]; then cp -R /etc/vnc/* ${STARTDIR}/${HOSTNAME}/etc/vnc ; fi

# OSX doesn't support virtual mode so we don't need xstartup for this platform
if [ -d $RCUHOMED/.vnc ]; then 
	if [ "${MYPLATFORM}" != "OSX" ]; then
		if [ -f $RCUHOMED/.vnc/xstartup ]; then cp $RCUHOMED/.vnc/xstartup ${STARTDIR}/${HOSTNAME}/userdotvnc/xstartup ; fi
		if [ -f $RCUHOMED/.vnc/xstartup.custom ]; then cp $RCUHOMED/.vnc/xstartup.custom ${STARTDIR}/${HOSTNAME}/userdotvnc/xstartup.custom ; fi
		if [ -f $RCUHOMED/vncserver-virtual.conf ]; then cp $RCUHOMED/vncserver-virtual.conf ${STARTDIR}/${HOSTNAME}/vncserver-virtual.conf ; fi
	else
		if [ -d /var/root/.vnc/config.d ]; then cp -R /var/root/.vnc/config.d ${STARTDIR}/${HOSTNAME}/rootdotvnc; fi
	fi
	if ls ${RCUHOMED}/.vnc/*.log 1> /dev/null 2>&1; then cp $RCUHOMED/.vnc/*.log ${STARTDIR}/${HOSTNAME}/logs/user; fi
	if [ -f $RCUHOMED/.vnc/config ]; then cp $RCUHOMED/.vnc/config ${STARTDIR}/${HOSTNAME}/userdotvnc/config ; fi
	if [ -d $RCUHOMED/.vnc/config.d ]; then cp -R $RCUHOMED/.vnc/config.d ${STARTDIR}/${HOSTNAME}/userdotvnc; fi
fi

# get system .vnc
if [ -d /.vnc ]; then cp -R /.vnc/* ${STARTDIR}/${HOSTNAME}/systemdotvnc; fi

# get root .vnc
if [ -d /root/.vnc/config.d ]; then cp -R /root/.vnc/config.d/* ${STARTDIR}/${HOSTNAME}/rootdotvnc/config.d; fi

find ${STARTDIR}/${HOSTNAME} -type f -name '*.key' -exec rm "{}" +
find ${STARTDIR}/${HOSTNAME} -type f -name '*.pkg' -exec rm "{}" +
find ${STARTDIR}/${HOSTNAME} -type f -name '*.bed' -exec rm "{}" +

# copy PAM rules
if [ -f /etc/pam.conf ]; then cp /etc/pam.conf ${STARTDIR}/${HOSTNAME}/etc/pam.conf; fi
if [ -d /etc/pam.d ]; then cp -R /etc/pam.d/* ${STARTDIR}/${HOSTNAME}/etc/pam.d; fi

# get system Xorg/X11
if [ -f /etc/X11/vncserver-virtual.conf ]; then cp /etc/X11/vncserver-virtual.conf ${STARTDIR}/${HOSTNAME}/etc/X11/vncserver-virtual.conf; fi

# Capture system environment details
# get linux version 
if [ "${MYPLATFORM}" = "Linux" ]; then
	cat /etc/*release > ${STARTDIR}/${HOSTNAME}/systemstate/linux-version.txt 2>/dev/null
fi

# get PCI hardware info for linux
if [ "${MYPLATFORM}" = "Linux" ]; then
	if [ -x /usr/bin/lspci ]; then /usr/bin/lspci  > ${STARTDIR}/${HOSTNAME}/systemstate/lspci.txt; fi
	if [ -x /sbin/lspci ]; then /sbin/lspci  > ${STARTDIR}/${HOSTNAME}/systemstate/lspci.txt; fi
fi

# get hardware info for OSX
if [ "${MYPLATFORM}" = "OSX" ]; then
	if [ -x /usr/sbin/system_profiler ]; then echo "Getting Mac hardware info..."; /usr/sbin/system_profiler -detailLevel mini > ${STARTDIR}/${HOSTNAME}/systemstate/macintosh_hardware_info.txt; fi
fi

env > ${STARTDIR}/${HOSTNAME}/systemstate/userenv.txt 2>/dev/null
uname -a > ${STARTDIR}/${HOSTNAME}/systemstate/sysinfo.txt 2>/dev/null
umask > ${STARTDIR}/${HOSTNAME}/systemstate/umask.txt 2>/dev/null
echo $ORIGPATH > ${STARTDIR}/${HOSTNAME}/systemstate/path.txt 2>/dev/null
if [ -f /etc/release ]; then
	cp /etc/release ${STARTDIR}/${HOSTNAME}/systemstate/release.txt 2>/dev/null
fi

# get X server details
if [ "${MYPLATFORM}" = "Linux" ]; then
	if [ -d /tmp/.X11-unix  -a `ls /tmp/.X11-unix | wc -l` -ne 0 ]; then 
		if type lsof > /dev/null 2>&1; then DISPMGR=`lsof -t /tmp/.X11-unix/*`; else echo "lsof not found, please install this using your preferred package manager"; exit 1; fi
		ps -p $DISPMGR > ${STARTDIR}/${HOSTNAME}/systemstate/xservers.txt 2>/dev/null
	fi
fi

# get root crontab
if [ "${MYPLATFORM}" = "Linux" ]; then
	crontab -u root -l > ${STARTDIR}/${HOSTNAME}/systemstate/rootcrontab.txt 2>/dev/null
fi

# get X session manager details
if [ "${MYPLATFORM}" = "Linux" ]; then
	if [ -d /usr/share/xsessions ]; then
		for i in `ls /usr/share/xsessions` ;
			do tmp=`grep TryExec /usr/share/xsessions/$i | cut -d"=" -f2`; echo $i ; pidof $tmp
		done >> ${STARTDIR}/${HOSTNAME}/systemstate/xsession_running.txt
	fi
fi

# get X settings info
if [ "${MYPLATFORM}" = "Linux" ]; then
	xset q > ${STARTDIR}/${HOSTNAME}/systemstate/xsettings.txt 2>/dev/null
fi

# list Xvnc control sockets in /tmp to help in identifying any permission issues
if [ "${MYPLATFORM}" = "Linux" ]; then
	find /tmp -name Xvnc* -type s -print > ${STARTDIR}/${HOSTNAME}/systemstate/tmp_virtualmode_sockets.txt 2>/dev/null
fi

# get any /tmp/.X lock files (virtual mode daemon only)
if [ "${MYPLATFORM}" = "Linux" ]; then
	ls -al /tmp/.X*-lock > ${STARTDIR}/${HOSTNAME}/systemstate/tmp_virtualmodedaemon_locks.txt 2>/dev/null
fi

# startup configuration
# Check for SysV and SysD on linux.
# initctl requires D-Bus so will not run over SSH tidily, check if it will fail and handle.
if [ "${MYPLATFORM}" = "Linux" ]; then
	if type systemctl > /dev/null 2>&1; then systemctl list-unit-files --type=service > ${STARTDIR}/${HOSTNAME}/startup/linux.systemd.txt; fi
	if type chkconfig > /dev/null 2>&1; then chkconfig --list > ${STARTDIR}/${HOSTNAME}/startup/linux.sysv.txt; fi
	if type initctl > /dev/null 2>&1; then 
		if initctl list > /dev/null 2>&1; then
			initctl list > ${STARTDIR}/${HOSTNAME}/startup/linux.upstart.txt
		else
			if [ -d /etc/init.d ]; then ls -al /etc/init.d > ${STARTDIR}/${HOSTNAME}/startup/linux.initd.txt; fi
			if [ -d /etc/rc0.d -o -d /etc/rc3.d ]; then ls -alR /etc/rc*.d > ${STARTDIR}/${HOSTNAME}/startup/linux.rc.txt; fi
		fi;
	fi;
fi
if [ "${MYPLATFORM}" = "AIX" ]; then
	lsitab -a > ${STARTDIR}/${HOSTNAME}/startup/aix.lsitab.txt 2>/dev/null
	ls -alR /etc/rc.d/ > ${STARTDIR}/${HOSTNAME}/startup/aix.rcd.txt 2>/dev/null
fi
if [ "${MYPLATFORM}" = "HPUX" ]; then
	if [ -d /sbin/init.d ]; then ls -al /sbin/init.d > ${STARTDIR}/${HOSTNAME}/startup/hpux.initd.txt; fi
	if [ -d /sbin/rc0.d -o -d /sbin/rc3.d ]; then ls -alR /etc/rc*.d > ${STARTDIR}/${HOSTNAME}/startup/hpux.rc.txt; fi
fi
if [ "${MYPLATFORM}" = "OSX" ]; then
	launchctl list > ${STARTDIR}/${HOSTNAME}/startup/darwin.txt 2>/dev/null
fi
if [ "${MYPLATFORM}" = "SOLARIS" ]; then
	if type svcs > /dev/null 2>&1; then svcs -a > ${STARTDIR}/${HOSTNAME}/startup/solaris.svcs.txt; fi
	if [ -d /etc/init.d ]; then ls -al /etc/init.d > ${STARTDIR}/${HOSTNAME}/startup/solaris.initd.txt; fi
	if [ -d /etc/rc0.d -o -d /etc/rc3.d ]; then ls -alR /etc/rc*.d > ${STARTDIR}/${HOSTNAME}/startup/solaric.rc.txt; fi
fi

# Gather VNC License information
if [ "${MYPLATFORM}" = "Linux" ]; then 
	if [ -f /usr/bin/vnclicense ]; then 
		/usr/bin/vnclicense -list > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicenselist.txt 2>/dev/null
		/usr/bin/vnclicense -check > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicensecheck.txt 2>/dev/null
	fi
fi
if [ "${MYPLATFORM}" = "SOLARIS" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; then
	if [ -f /usr/local/bin/vnclicense ]; then
		/usr/local/bin/vnclicense -list > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicenselist.txt 2>/dev/null
		/usr/local/bin/vnclicense -check > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicensecheck.txt 2>/dev/null
	fi;
fi
if [  "${MYPLATFORM}" = "OSX" ]; then
	if [ -f /Library/vnc/vnclicense ]; then
		/Library/vnc/vnclicense -list > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicenselist.txt 2>/dev/null
		/Library/vnc/vnclicense -check > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicensecheck.txt 2>/dev/null
	fi;
fi

# Gather running processes
# Apply the Z modifier on SELinux systems to get appropriate information relevant to that.
if [ "${SELINUX}" = "1" ]; then
	ps -efZ | grep -i vnc | grep -v vncexplorer | grep -v grep > ${STARTDIR}/${HOSTNAME}/systemstate/vncprocs.txt
else
	ps -ef | grep -i vnc | grep -v vncexplorer | grep -v grep > ${STARTDIR}/${HOSTNAME}/systemstate/vncprocs.txt
fi

# Gather network configuration
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" -o "${MYPLATFORM}" = "AIX" ]; then ifconfig -a > ${STARTDIR}/${HOSTNAME}/systemstate/ifconfig.txt; fi
if [ "${MYPLATFORM}" = "HPUX" ]; then
	LANINT=`lanscan | grep lan | grep -v LinkAgg | awk '{print $5}'`
	for THISLAN in ${LANINT} ; do
		ifconfig $THISLAN >> ${STARTDIR}/${HOSTNAME}/systemstate/ifconfig.txt
	done
fi
# HP-UX may throw an error, this is not unexpected, and should not cause a problem.

# Process to Port mapping.
if [ "${MYPLATFORM}" = "Linux" ]; then
	netstat -lntp > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.linux.txt
fi

if [ "${MYPLATFORM}" = "SOLARIS" ]; then
	for x in `ps -ef | grep vnc | awk '{ print $2}'`; do
		ps -fp $x | grep $x > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.solaris.txt
		pfiles $x | grep "port:" > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.solaris.txt
	done
	#Identify PIDS for vnc, then output "ps -fp" and "pfiles" for each entry
fi

if [ "${MYPLATFORM}" = "OSX" ]; then
	lsof -i > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.darwin.txt
fi

# power saving settings
# users will have issues if their remote machine has gone to sleep, so let's get power saving settings
# on OSX do through systemsetup -getcomputersleep
if [ "${MYPLATFORM}" = "OSX" ]; then
	/usr/sbin/systemsetup -getcomputersleep > ${STARTDIR}/${HOSTNAME}/systemstate/macos.sleepsetting.txt
fi

# Maintainers: we do *NOT* want to run pfiles against other processes
# doing so could potentially cause stability issues.
if [ "${MYPLATFORM}" = "HPUX" ]; then
	for x in `ps -ef | grep vnc | grep -v grep | grep -v vncexplorer | awk '{ print $2}'`; do
		ps -fp $x | grep $x >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.hpux.txt
		pfiles $x | grep "port =" | awk '{print "          " $3}' >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.hpux.txt
	done
fi

# We can't use the pfiles trick on AIX, so lets use netstat then pass the sockets to rmsock to return the information we need.
if [ "${MYPLATFORM}" = "AIX" ]; then
	echo "----------------------------------------------------------------------------" >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt
	printf "| %-20s | %-15s | Protocol | %-20s |\n" "Process" "PID" "Listening On" >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt
	echo "----------------------------------------------------------------------------" >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt

	netstat -Ana | awk '
	/[0-9\*].[0-9].+LISTEN/ {
		SOCKETNUM=$1;
		PORTNUM=$5;
		"rmsock " SOCKETNUM " tcpcb" | getline SOCKETLIST;
		split(SOCKETLIST, socketarray, " ");
		gsub(/[\.\(\)]/, "", socketarray[10]);
		OUTPUTARRAY[ sprintf("| %-20s | %15d | %8s | %20s |", socketarray[10], socketarray[9], "TCP", PORTNUM) ] = 1;
	}
	/udp.*.[0-9]/ {
		SOCKETNUM=$1;
		PORTNUM=$5;
		"rmsock " SOCKETNUM " inpcb" | getline SOCKETLIST;
		split(SOCKETLIST, socketarray, " ");
		gsub(/[\.\(\)]/, "", socketarray[10]);
		OUTPUTARRAY[ sprintf("| %-20s | %15d | %8s | %20s |", socketarray[10], socketarray[9], "UDP", PORTNUM) ] = 1;
	}
	END {
		for (var in OUTPUTARRAY)
			print var

	}' | sort | uniq >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt

	echo "----------------------------------------------------------------------------" >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt
fi

# Security tools check
if type sestatus > /dev/null 2>&1; then sestatus > ${STARTDIR}/${HOSTNAME}/systemstate/sestatus.txt; fi
if type iptables > /dev/null 2>&1; then iptables -L > ${STARTDIR}/${HOSTNAME}/systemstate/iptables.txt; fi

#Output runlevel to a file
if type runlevel > /dev/null 2>&1; then runlevel > ${STARTDIR}/${HOSTNAME}/systemstate/runlevel.txt; fi

# installed packages
# No check for AIX at the current time. Use the binary file listing.
if type dpkg > /dev/null 2>&1; then dpkg -l | grep -i vnc > ${STARTDIR}/${HOSTNAME}/systemstate/packages.vnc.deb.txt; dpkg -l | grep -i xserver-xorg-video-dummy > ${STARTDIR}/${HOSTNAME}/systemstate/packages.drv.txt; fi
if type rpm > /dev/null 2>&1; then rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n' | grep -i vnc > ${STARTDIR}/${HOSTNAME}/systemstate/packages.vnc.rpm.txt; rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n' | grep -i xorg-x11-drv-dummy > ${STARTDIR}/${HOSTNAME}/systemstate/packages.drv.rpm.txt; fi
if [ "${MYPLATFORM}" = "SOLARIS" ]; then
	pkginfo | grep -i vnc >> ${STARTDIR}/${HOSTNAME}/systemstate/packages.solaris.txt
elif [ "${MYPLATFORM}" = "HPUX" ]; then
	/usr/sbin/swlist | grep -i vnc >> ${STARTDIR}/${HOSTNAME}/systemstate/packages.hpux.txt
elif [ "${MYPLATFORM}" = "OSX" ]; then
	pkgutil --pkgs >> ${STARTDIR}/${HOSTNAME}/systemstate/packages.darwin.txt
fi

# Pull any log files which exist.
if [ "${MYPLATFORM}" = "OSX" ]; then
	if ls /Library/Logs/vnc*.log > /dev/null 2>&1; then cp /Library/Logs/vnc*.log ${STARTDIR}/${HOSTNAME}/logs/system/; fi
	if ls /Library/Logs/vnc*.log.bak > /dev/null 2>&1; then cp /Library/Logs/vnc*.log.bak ${STARTDIR}/${HOSTNAME}/logs/system/; fi
	if ls ${HOME}/Library/Logs/vnc/*.log > /dev/null 2>&1; then cp ${HOME}/Library/Logs/vnc/*.log ${STARTDIR}/${HOSTNAME}/logs/user/; fi
	if ls ${HOME}/Library/Logs/vnc/*.log.bak > /dev/null 2>&1; then cp ${HOME}/Library/Logs/vnc/*.log.bak ${STARTDIR}/${HOSTNAME}/logs/user/; fi
else
	if ls /var/log/vnc*.log > /dev/null 2>&1; then cp /var/log/vnc*.log ${STARTDIR}/${HOSTNAME}/logs/system/; fi
	if ls /var/log/vnc*.log.bak > /dev/null 2>&1; then cp /var/log/vnc*.log.bak ${STARTDIR}/${HOSTNAME}/logs/system/; fi
	if ls /var/log/Xorg*.log > /dev/null 2>&1; then cp /var/log/Xorg*.log ${STARTDIR}/${HOSTNAME}/logs/system/; fi
	if ls /var/log/Xorg*.log.bak > /dev/null 2>&1; then cp /var/log/Xorg*.log.bak ${STARTDIR}/${HOSTNAME}/logs/system/; fi
fi

# VNC Directory long listing (permissions, selinux contexts)
if [ -d /etc/vnc ]; then
	if [ "${SELINUX}" = "1" ];
	then ls -alZ /etc/vnc > ${STARTDIR}/${HOSTNAME}/filesystem/etc-vnc.txt
	else ls -al /etc/vnc > ${STARTDIR}/${HOSTNAME}/filesystem/etc-vnc.txt
	fi;
fi

# /root/.vnc
if [ -d ~/.vnc ]; then
	if [ "${SELINUX}" = "1" ];
	then ls -alZ ~/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/root-.vnc.txt
	else ls -al ~/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/root-.vnc.txt
	fi;
fi

# container for home directories (Linux, AIX, HPUX)
if [ -d /home ]; then
	if [ "${SELINUX}" = "1" ]; 
	then ls -lZ /home > ${STARTDIR}/${HOSTNAME}/filesystem/home.txt
	else ls -l /home > ${STARTDIR}/${HOSTNAME}/filesystem/home.txt
	fi;
fi

# container for home directories (Darwin)
if [ -d /Users ]; then
	ls -al /Users > ${STARTDIR}/${HOSTNAME}/filesystem/users.txt
fi

# container for home directories (Solaris)
if [ -d /export/home ]; then
	ls -al /export/home > ${STARTDIR}/${HOSTNAME}/filesystem/export.home.txt
fi

if [ -d ${RCUHOMED}/.vnc ]; then
	if [ "${SELINUX}" = "1" ];
	then ls -alZ ${RCUHOMED}/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/user-vnc.txt
	else ls -al ${RCUHOMED}/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/user-vnc.txt
	fi;
fi

# Solaris, AIX, HPUX binary file listing
if [ "${MYPLATFORM}" = "SOLARIS" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; 
	then 
		if [ -d /usr/local/bin ];
			then ls -al /usr/local/bin/vnc* >> ${STARTDIR}/${HOSTNAME}/filesystem/usr-local-bin.txt
		fi;
fi

# Linux binary file listing
if [ "${MYPLATFORM}" = "Linux" ]; 
	then 
		if ls /usr/bin/vnc* > /dev/null 2>&1; then
			if [ "${SELINUX}" = "1" ];
				then ls -alZ /usr/bin/vnc* > ${STARTDIR}/${HOSTNAME}/filesystem/usr-bin.txt
				else ls -al /usr/bin/vnc* > ${STARTDIR}/${HOSTNAME}/filesystem/usr-bin.txt
			fi;
		fi;
fi

# Darwin binary file listing
if [  "${MYPLATFORM}" = "OSX" ]; 
	then 
		if [ -d /Library/vnc ];
			then ls -al /Library/vnc/ > ${STARTDIR}/${HOSTNAME}/filesystem/library-vnc.txt
		fi;
fi

# if netcat exists, check for common VNC ports
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" ]; then
	if type "nc"  > /dev/null 2>&1; then
		nc -z -v -w5 localhost 5900-5909 2>${STARTDIR}/${HOSTNAME}/systemstate/netcat.txt
		nc -z -v -w5 localhost 5999 2>>${STARTDIR}/${HOSTNAME}/systemstate/netcat.txt
	fi
fi

set +e
# Pack it all up
cd ${STARTDIR}
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" ]; then
	tar -czf ${TEMPDIR}/vncsupport-${HOSTNAME}.tar.gz ${HOSTNAME}
else
	tar -cf ${TEMPDIR}/vncsupport-${HOSTNAME}.tar ${HOSTNAME}
fi

# Clean up
echo "cleaning up ${STARTDIR}/${HOSTNAME}. "
rm -rf ${STARTDIR}/${HOSTNAME}

if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" ]; then
	
	echo "Reverting logging to pre-script value"
	if [ "${POLICYEXISTS}" = "0" ] ; then
		rm -f /etc/vnc/policy.d/common
	else
		sed -i '' 's/^Log=.*/'"${EXISTINGLOG}"'/g' /etc/vnc/policy.d/common
	fi
fi


echo ""
echo "Please attach the following file to your RealVNC Customer Support ticket:"
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" ]; then
	echo "$TEMPDIR/vncsupport-${HOSTNAME}.tar.gz"
else
	echo "$TEMPDIR/vncsupport-${HOSTNAME}.tar"
fi

exit 0
