#!/bin/sh 

# Copyright (C) 2016 RealVNC Limited. All rights reserved.
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

set -e
#set standard UNIX paths in case these are not set
ORIGPATH=$PATH
PATH=$PATH:/bin:/sbin:/usr/sbin:/usr/bin:/usr/ucb

# platform detection
MYPLATFORM="none"
if [ `uname -a | grep Linux | wc -l` -ge 1 ]; then MYPLATFORM="Linux"; fi
if [ `uname -a | grep AIX | wc -l` -ge 1 ]; then MYPLATFORM="AIX"; fi
if [ `uname -a | grep HP-UX | wc -l` -ge 1 ]; then MYPLATFORM="HPUX"; fi
if [ `uname -a | grep SunOS | wc -l` -ge 1 ]; then MYPLATFORM="SOLARIS"; fi
if [ `uname -a | grep Darwin | wc -l` -ge 1 ]; then MYPLATFORM="OSX"; fi
if [ "${MYPLATFORM}" = "none" ]; then echo "ERROR: Unsupported platform. Aborting..."; fi
echo "Platform: ${MYPLATFORM}"

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
echo "Data collected: "
echo "The contents of /etc/vnc, /etc/pam.d, current user .vnc directory,"
echo "currently running processes, current user environment, system IP address"
echo "information, system hardware details and vnc license information. "
echo "Private keys and chat history are NOT included"
echo "Press enter to accept this and continue or press CTRL+C to cancel"
read accept
set -e

# set initial variables
STARTDIR=`pwd`
CURRUSER=`whoami`

# prompt for username to collect $HOME/.vnc 
echo "Enter non-root username (relevant only for user and/or virtual mode servers)"
read USERENTERED
REALUSER=${USERENTERED}
echo "collecting details for: $REALUSER"
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; then
RCUHOMED=`cat /etc/passwd | grep \^$REALUSER\: | cut -d":" -f6`
echo "RCUHOMED: $RCUHOMED"
if [ -z ${RCUHOMED} ]; then echo "cannot determine non-root user home directory. Aborting..."; exit; fi
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
if [ -f ${TEMPDIR}/vncsupport-${HOSTNAME}.tar ]; then
echo "removing old vncexplorer data"; 
rm ${TEMPDIR}/vncsupport-${HOSTNAME}.tar;
fi

# ensure STARTDIR and HOSTNAME are not empty
if [ -z ${STARTDIR} ]; then echo "Environment error encountered. Aborting..."; exit ; fi
if [ -z ${HOSTNAME} ]; then echo "Environment error encountered. Aborting..."; exit ; fi
# warn user that this exists - do they want to remove or keep?
if [ -d ${STARTDIR}/${HOSTNAME} ]; then echo "$STARTDIR/$HOSTNAME exists - CTRL+C to cancel this script or enter to continue (${STARTDIR}/${HOSTNAME} will be deleted)"; read accept2; fi
if [ -d ${STARTDIR}/${HOSTNAME} ]; then rm -rf ${STARTDIR}/${HOSTNAME} ; fi

# create initial directory structure
set +e
mkdir ${STARTDIR}/${HOSTNAME}
mkdir ${STARTDIR}/${HOSTNAME}/etc
mkdir ${STARTDIR}/${HOSTNAME}/etc/vnc
mkdir ${STARTDIR}/${HOSTNAME}/etc/vnc/policy.d
mkdir ${STARTDIR}/${HOSTNAME}/etc/pam.d
mkdir ${STARTDIR}/${HOSTNAME}/userdotvnc
mkdir ${STARTDIR}/${HOSTNAME}/userdotvnc/VNCAddressBook
mkdir ${STARTDIR}/${HOSTNAME}/userdotvnc/config.d
mkdir ${STARTDIR}/${HOSTNAME}/systemstate
mkdir ${STARTDIR}/${HOSTNAME}/filesystem
mkdir ${STARTDIR}/${HOSTNAME}/logs
mkdir ${STARTDIR}/${HOSTNAME}/logs/user
mkdir ${STARTDIR}/${HOSTNAME}/logs/system
mkdir ${STARTDIR}/${HOSTNAME}/startup

# copy relevant VNC configuration files
if [ -d /etc/vnc ] ; then cp -R /etc/vnc/* ${STARTDIR}/${HOSTNAME}/etc/vnc ; fi
# OSX doesn't support virtual mode so we don't need xstartup for this platform
if [ -d $RCUHOMED/.vnc ] ; then 
 if [ "${MYPLATFORM}" != "OSX" ]; then cp $RCUHOMED/.vnc/xstartup ${STARTDIR}/${HOSTNAME}/userdotvnc ; fi
 if ls ${RCUHOMED}/.vnc/*.log 1> /dev/null 2>&1 ; then cp $RCUHOMED/.vnc/*.log ${STARTDIR}/${HOSTNAME}/logs/user; fi
cp -R $RCUHOMED/.vnc/config.d ${STARTDIR}/${HOSTNAME}/userdotvnc;
fi

if [ -d $HOME/.vnc/VNCAddressBook ] ; then
cp -R $HOME/.vnc/VNCAddressBook ${STARTDIR}/${HOSTNAME}/userdotvnc;
fi
# copy PAM rules
if [ -f /etc/pam.conf ]; then cp -R /etc/pam.conf ${STARTDIR}/${HOSTNAME}/etc; fi
if [ -d /etc/pam.d ]; then cp -R /etc/pam.d/* ${STARTDIR}/${HOSTNAME}/etc/pam.d; fi

# Capture system environment details
# get linux version 
if [ "${MYPLATFORM}" = "Linux" ]; then
  cat /etc/*release > ${STARTDIR}/${HOSTNAME}/systemstate/linux-version.txt	
fi
# get PCI hardware info for linux
if [ "${MYPLATFORM}" = "Linux" ]; then
  if [ -x /usr/bin/lspci ]; then /usr/bin/lspci  > ${STARTDIR}/${HOSTNAME}/systemstate/lspci.txt; fi
  if [ -x /sbin/lspci ]; then /sbin/lspci  > ${STARTDIR}/${HOSTNAME}/systemstate/lspci.txt; fi
fi

# get hardware info for OSX
if [ "${MYPLATFORM}" = "OSX" ]; then
  if [ -x /usr/sbin/system_profiler ]; then /usr/sbin/system_profiler -detailLevel mini > ${STARTDIR}/${HOSTNAME}/systemstate/macintosh_hardware_info.txt; fi
fi

env > ${STARTDIR}/${HOSTNAME}/systemstate/userenv.txt
logname > ${STARTDIR}/${HOSTNAME}/systemstate/actualuser.txt
uname -a > ${STARTDIR}/${HOSTNAME}/systemstate/sysinfo.txt
umask > ${STARTDIR}/${HOSTNAME}/systemstate/umask.txt
echo $ORIGPATH > ${STARTDIR}/${HOSTNAME}/systemstate/path.txt
if [ -f /etc/release ]; then
	cp /etc/release ${STARTDIR}/${HOSTNAME}/systemstate/release.txt;
fi
# get X server details
if [ "${MYPLATFORM}" = "Linux" ]; then
	if [ -d /tmp/.X11-unix  -a `ls /tmp/.X11-unix | wc -l` -ne 0 ]; then 
	DISPMGR=`lsof -t /tmp/.X11-unix/*`
	ps -p $DISPMGR > ${STARTDIR}/${HOSTNAME}/systemstate/xservers.txt
	fi
fi
# get X session manager details
if [ "${MYPLATFORM}" = "Linux" ]; then
    if [ -d /usr/share/xsessions ];
    then
    for i in `ls /usr/share/xsessions` ;
        do tmp=`grep TryExec /usr/share/xsessions/$i | cut -d"=" -f2`; echo $i ; pidof $tmp  
    done >> ${STARTDIR}/${HOSTNAME}/systemstate/xsession_running.txt
    fi
fi

	
# list Xvnc control sockets in /tmp to help in identifying any permission issues
if [ "${MYPLATFORM}" = "Linux" ]; then
	find /tmp -name Xvnc* -type s -print > ${STARTDIR}/${HOSTNAME}/systemstate/tmp_virtualmode_sockets.txt
fi

# startup configuration
# Check for SysV and SysD on linux.
# initctl requires D-Bus so will not run over SSH tidily, check if it will fail and handle.
if [ "${MYPLATFORM}" = "Linux" ]; then
	if type systemctl > /dev/null 2>&1; then systemctl list-unit-files --type=service > ${STARTDIR}/${HOSTNAME}/startup/linux.systemd.txt; fi;
	if type chkconfig > /dev/null 2>&1; then chkconfig --list > ${STARTDIR}/${HOSTNAME}/startup/linux.sysv.txt; fi;
	if type initctl > /dev/null 2>&1; then 
		if initctl list > /dev/null 2>&1; then
			initctl list > ${STARTDIR}/${HOSTNAME}/startup/linux.upstart.txt; 
		else
			if [ -d /etc/init.d ]; then ls -al /etc/init.d > ${STARTDIR}/${HOSTNAME}/startup/linux.initd.txt; fi;
			if [ -d /etc/rc0.d -o -d /etc/rc3.d ]; then ls -alR /etc/rc*.d > ${STARTDIR}/${HOSTNAME}/startup/linux.rc.txt; fi;
		fi;
	fi;
fi

if [ "${MYPLATFORM}" = "AIX" ]; then
	lsitab -a > ${STARTDIR}/${HOSTNAME}/startup/aix.lsitab.txt;
	ls -alR /etc/rc.d/ > ${STARTDIR}/${HOSTNAME}/startup/aix.rcd.txt;
fi
if [ "${MYPLATFORM}" = "HPUX" ]; then
	if [ -d /sbin/init.d ]; then ls -al /sbin/init.d > ${STARTDIR}/${HOSTNAME}/startup/hpux.initd.txt; fi;
	if [ -d /sbin/rc0.d -o -d /sbin/rc3.d ]; then ls -alR /etc/rc*.d > ${STARTDIR}/${HOSTNAME}/startup/hpux.rc.txt; fi;
fi
if [ "${MYPLATFORM}" = "OSX" ]; then
	launchctl list > ${STARTDIR}/${HOSTNAME}/startup/darwin.txt;
fi
if [ "${MYPLATFORM}" = "SOLARIS" ]; then
	if type svcs > /dev/null 2>&1; then svcs -a > ${STARTDIR}/${HOSTNAME}/startup/solaris.svcs.txt; fi;
	if [ -d /etc/init.d ]; then ls -al /etc/init.d > ${STARTDIR}/${HOSTNAME}/startup/solaris.initd.txt; fi;
	if [ -d /etc/rc0.d -o -d /etc/rc3.d ]; then ls -alR /etc/rc*.d > ${STARTDIR}/${HOSTNAME}/startup/solaric.rc.txt; fi;
fi



# Gather VNC License information
if [ "${MYPLATFORM}" = "Linux" ]; then 
	if [ -f /usr/bin/vnclicense ]; then 
		/usr/bin/vnclicense -list > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicenselist.txt;
		/usr/bin/vnclicense -check > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicensecheck.txt;
	fi;
fi
if [ "${MYPLATFORM}" = "SOLARIS" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; then
	if [ -f /usr/local/bin/vnclicense ]; then
		/usr/local/bin/vnclicense -list > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicenselist.txt; 
		/usr/local/bin/vnclicense -check > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicensecheck.txt;
	fi;
fi
if [  "${MYPLATFORM}" = "OSX" ]; then
	if [ -f /Library/vnc/vnclicense ]; then
		/Library/vnc/vnclicense -list > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicenselist.txt; 
		/Library/vnc/vnclicense -check > ${STARTDIR}/${HOSTNAME}/systemstate/vnclicensecheck.txt;
	fi;
fi

# Gather running processes
# Apply the Z modifier on SELinux systems to get appropriate information relevant to that.
if [ "${SELINUX}" = "1" ]; 
	then ps -efZ | grep -i vnc | grep -v vncexplorer | grep -v grep > ${STARTDIR}/${HOSTNAME}/systemstate/vncprocs.txt;
	else ps -ef | grep -i vnc | grep -v vncexplorer | grep -v grep > ${STARTDIR}/${HOSTNAME}/systemstate/vncprocs.txt;
fi
# Gather network configuration
if [ "${MYPLATFORM}" = "Linux" -o "${MYPLATFORM}" = "OSX" -o "${MYPLATFORM}" = "AIX" ]; then ifconfig -a > ${STARTDIR}/${HOSTNAME}/systemstate/ifconfig.txt; fi
if [ "${MYPLATFORM}" = "HPUX" ]; then
	LANINT=`lanscan | grep lan | grep -v LinkAgg | awk '{print $5}'`
	for THISLAN in ${LANINT} ; do
		#echo $THISLAN;
		ifconfig $THISLAN >> ${STARTDIR}/${HOSTNAME}/systemstate/ifconfig.txt
	done
fi
# HP-UX may throw an error, this is not unexpected, and should not cause a problem.

# Process to Port mapping.

if [ "${MYPLATFORM}" = "Linux" ]; then 
	netstat -lntp > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.linux.txt;
fi

if [ "${MYPLATFORM}" = "SOLARIS" ]; then 
	for x in `ps -ef | grep vnc | awk '{ print $2}'`; do 	
		ps -fp $x | grep $x > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.solaris.txt; 
		pfiles $x | grep "port:" > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.solaris.txt; 
	done;
	#Identify PIDS for vnc, then output "ps -fp" and "pfiles" for each entry
fi

if [ "${MYPLATFORM}" = "OSX" ]; 
then lsof -i > ${STARTDIR}/${HOSTNAME}/systemstate/netstat.darwin.txt;
fi

# Maintainers: we do *NOT* want to run pfiles against other processes
# doing so could potentially cause stability issues.
if [ "${MYPLATFORM}" = "HPUX" ]; then
	for x in `ps -ef | grep vnc | grep -v grep | grep -v vncexplorer | awk '{ print $2}'`; do
		ps -fp $x | grep $x >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.hpux.txt;
		pfiles $x | grep "port =" | awk '{print "          " $3}' >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.hpux.txt;
	done;
fi;

# We can't use the pfiles trick on AIX, so lets use netstat then pass the sockets to rmsock to return the information we need.
if [ "${MYPLATFORM}" = "AIX" ] ; then
    echo "----------------------------------------------------------------------------" >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt
    printf "| %-20s | %-15s | Protocol | %-20s |\n" "Process" "PID" "Listening On" >> ${STARTDIR}/${HOSTNAME}/systemstate/netstat.aix.txt;
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

# installed packages
# No check for AIX at the current time. Use the binary file listing.

if type dpkg > /dev/null 2>&1; then dpkg -l | grep -i vnc > ${STARTDIR}/${HOSTNAME}/systemstate/packages.deb.txt; fi
if type rpm > /dev/null 2>&1; then rpm -qa --qf '%{NAME}-%{VERSION}-%{RELEASE} (%{ARCH})\n' | grep -i vnc > ${STARTDIR}/${HOSTNAME}/systemstate/packages.rpm.txt; fi
if [ "${MYPLATFORM}" = "SOLARIS" ]; then
	pkginfo | grep -i vnc >> ${STARTDIR}/${HOSTNAME}/systemstate/packages.solaris.txt;
fi
if [ "${MYPLATFORM}" = "HPUX" ]; then
	/usr/sbin/swlist | grep -i vnc >> ${STARTDIR}/${HOSTNAME}/systemstate/packages.hpux.txt;
fi
if [ "${MYPLATFORM}" = "OSX" ]; then
	pkgutil --pkgs >> ${STARTDIR}/${HOSTNAME}/systemstate/packages.darwin.txt;
fi



# Pull any log files which exist.
if [ "${MYPLATFORM}" = "OSX" ]; then
	if ls /Library/Logs/vnc*.log > /dev/null 2>&1; then cp /Library/Logs/vnc*.log ${STARTDIR}/${HOSTNAME}/logs/system/; fi;
	if ls /Library/Logs/vnc*.log.bak > /dev/null 2>&1; then cp /Library/Logs/vnc*.log.bak ${STARTDIR}/${HOSTNAME}/logs/system/; fi;
	if ls ${HOME}/Library/Logs/vnc/*.log > /dev/null 2>&1; then cp ${HOME}/Library/Logs/vnc/*.log ${STARTDIR}/${HOSTNAME}/logs/user/; fi;
	if ls ${HOME}/Library/Logs/vnc/*.log.bak > /dev/null 2>&1; then cp ${HOME}/Library/Logs/vnc/*.log.bak ${STARTDIR}/${HOSTNAME}/logs/user/; fi;
fi

if [ "${MYPLATFORM}" != "OSX" ]; then
	if ls /var/log/vnc*.log > /dev/null 2>&1; then cp /var/log/vnc*.log ${STARTDIR}/${HOSTNAME}/logs/system/; fi;
	if ls /var/log/vnc*.log.bak > /dev/null 2>&1; then cp /var/log/vnc*.log.bak ${STARTDIR}/${HOSTNAME}/logs/system/; fi;
	if ls ${RCUHOMED}/.vnc/*.log > /dev/null 2>&1; then cp ${RCUHOMED}/.vnc/*.log ${STARTDIR}/${HOSTNAME}/logs/user/; fi;
	if ls ${RCUHOMED}/.vnc/*.log.bak > /dev/null 2>&1; then cp ${RCUHOMED}/.vnc/*.log.bak ${STARTDIR}/${HOSTNAME}/logs/user/; fi;
fi


# VNC Directory long listing (permissions, selinux contexts)
if [ -d /etc/vnc ]; then
  if [ "${SELINUX}" = "1" ];
	then ls -alZ /etc/vnc > ${STARTDIR}/${HOSTNAME}/filesystem/etc-vnc.txt; 
  	else ls -al /etc/vnc > ${STARTDIR}/${HOSTNAME}/filesystem/etc-vnc.txt;
  fi;
fi
# /root/.vnc
if [ -d ~/.vnc ]; then
  if [ "${SELINUX}" = "1" ];
	then ls -alZ ~/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/root-.vnc.txt;
	else ls -al ~/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/root-.vnc.txt;
  fi;
fi

# container for home directories (Linux, AIX, HPUX)
if [ -d /home ]; then
  if [ "${SELINUX}" = "1" ]; 
	then ls -lZ /home > ${STARTDIR}/${HOSTNAME}/filesystem/home.txt; 
	else ls -l /home > ${STARTDIR}/${HOSTNAME}/filesystem/home.txt; 
  fi;
fi
# container for home directories (Darwin)
if [ -d /Users ]; then
  ls -al /Users > ${STARTDIR}/${HOSTNAME}/filesystem/users.txt;
fi
# container for home directories (Solaris)
if [ -d /export/home ]; then
	ls -al /export/home > ${STARTDIR}/${HOSTNAME}/filesystem/export.home.txt;
fi

if [ -d ${RCUHOMED}/.vnc ]; then
  if [ "${SELINUX}" = "1" ];
	then ls -alZ ${RCUHOMED}/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/user-vnc.txt;
	else ls -al ${RCUHOMED}/.vnc > ${STARTDIR}/${HOSTNAME}/filesystem/user-vnc.txt;
  fi;
fi
# Solaris, AIX, HPUX binary file listing
if [ "${MYPLATFORM}" = "SOLARIS" -o "${MYPLATFORM}" = "AIX" -o "${MYPLATFORM}" = "HPUX" ]; 
	then 
		if [ -d /usr/local/bin ];
			then ls -al /usr/local/bin/vnc* >> ${STARTDIR}/${HOSTNAME}/filesystem/usr-local-bin.txt;
		fi;
fi
# Linux binary file listing
if [ "${MYPLATFORM}" = "Linux" ]; 
	then 
		if ls /usr/bin/vnc* > /dev/null 2>&1; then
			if [ "${SELINUX}" = "1" ];
				then ls -alZ /usr/bin/vnc* > ${STARTDIR}/${HOSTNAME}/filesystem/usr-bin.txt;
				else ls -al /usr/bin/vnc* > ${STARTDIR}/${HOSTNAME}/filesystem/usr-bin.txt;
			fi;
		fi;
fi
# Darwin binary file listing
if [  "${MYPLATFORM}" = "OSX" ]; 
	then 
		if [ -d /Library/vnc ];
			then ls -al /Library/vnc/ > ${STARTDIR}/${HOSTNAME}/filesystem/library-vnc.txt;
		fi;
fi


# Get Linux/UNIX/OSX policy 
if [ -d /etc/vnc/policy.d ];
then cp -R /etc/vnc/policy.d/* ${STARTDIR}/${HOSTNAME}/etc/vnc/policy.d;
fi


set +e
# Pack it all up
cd ${STARTDIR}
tar cf ${TEMPDIR}/vncsupport-${HOSTNAME}.tar ${HOSTNAME}
# Clean up
echo "cleaning up ${STARTDIR}/${HOSTNAME}. "
rm -rf ${STARTDIR}/${HOSTNAME}

echo ""
echo "Please attach the following file to your RealVNC Customer Support ticket:"
echo "$TEMPDIR/vncsupport-${HOSTNAME}.tar"
