#!/bin/bash

mydir=$(dirname "$0");
source $mydir/modules/CiscoSSLVPN.sh &> /dev/null;
source $mydir/modules/Netscaler.sh &> /dev/null;
source $mydir/modules/SonicWallVOffice.sh &> /dev/null;
source $mydir/modules/OWA2016.sh &> /dev/null;
source $mydir/modules/Gmail.sh &> /dev/null;
source $mydir/modules/Office365.sh &> /dev/null;
source $mydir/modules/PaloAlto.sh &> /dev/null;
source $mydir/modules/SharePoint.sh &> /dev/null;
source $mydir/modules/AUTO.sh &> /dev/null;
source $mydir/modules/SMB.sh &> /dev/null;
source $mydir/modules/XenMobile.sh &> /dev/null;
source $mydir/modules/Okta.sh &> /dev/null;
source $mydir/modules/XenApp.sh &> /dev/null;

#Help Banner Function...
Help_banner(){
if [[ ! -f $mydir/modules/SonicWallVOffice.sh ]] || [[ ! -f $mydir/modules/CiscoSSLVPN.sh ]] || [[ ! -f $mydir/modules/Netscaler.sh ]] || [[ ! -f $mydir/modules/OWA2016.sh ]] || [[ ! -f $mydir/modules/Gmail.sh ]] || [[ ! -f $mydir/modules/Office365.sh ]] || [[ ! -f $mydir/modules/PaloAlto.sh ]] || [[ ! -f $mydir/modules/SharePoint.sh ]] || [[ ! -f $mydir/modules/AUTO.sh ]] || [[ ! -f $mydir/modules/SMB.sh ]] || [[ ! -f $mydir/modules/XenMobile.sh ]] || [[ ! -f $mydir/modules/Okta.sh ]]; then
echo "Not All Modules Loaded.";
echo "Exiting...";
exit 1;
else
:
fi

echo "conformer v0.6.1";
echo "bk201@foofus.net";
echo "";
echo "usage: conformer.sh <HOST_IP/Hostname><:PORT>(optional) <Username or Users_File> 
       <Password<\\&par1=val1\\&par2=val2>(optional) or Pass_File> <Portal Type> 
       <DISABLE_CHECK>(optional) <DEBUG=file>(optional) <LOG=file>(optional)
       <THREAD=n>(optional) <SLEEP=n(seconds)(optional)>";
echo "";
echo "Portal Types: SonicWallVOffice
              CiscoSSLVPN
              Netscaler
	      OWA (versions 2013/2016)
              Gmail (Host: mail.google.com) (Google throttling authentication attempts)
              Office365 (Host: outlook.office.com)
              PaloAlto (GlobalProtect)
              SharePoint
              XenMobile
              XenApp (Incomplete)
              Okta (Incomplete)
              AUTO (Attempt autodetect module)
              --------------------------------
              SMB (Windows Auth. / supports NT Hash)"; #XenApp";


echo "";
echo "Type @SAME@ - Password=Username"
echo "DISABLE_CHECK - Disable Check if compatible Portal.";
echo "DEBUG - outputs HTTP responses to file";
echo "LOG - outputs stdout to file"
echo "THREAD - Threading of POST requests to server"
echo "SLEEP - Delay between POST requests to server, good if suspect of being throttled/blacklisted."
echo "SLEEP and THREAD cannot be used together!."
echo "";
echo "syntax examples.";
echo "conformer.sh domain.example.com username ~/Desktop/passwords CiscoSSLVPN";
echo "conformer.sh domain.example.com ~/Desktop/users ~/Desktop/passwords OWA THREAD=10";
echo "conformer.sh mail.google.com ~/Desktop/users ~/Desktop/passwords Gmail SLEEP=15";
echo "conformer.sh domain.example.com username password123 Gmail LOG=~/Desktop/log DEBUG=~/Desktop/debug";
echo "conformer.sh domain.example.com ~/Desktop/users Password1 Netscaler DISABLE_CHECK DEBUG=~/Desktop/debug";
echo "conformer.sh domain.example.com combo ~/Desktop/combofile(:user:pass) Netscaler";
echo "";
}

#Function to check proper parameters used.
parameter_check(){
#Where script would Update
if [[ $(echo "$1" | tr '[:upper:]' '[:lower:]') == "update" ]]; then
echo "Not Available Option.";
#rm conformer.sh;
#wget https://raw.githubusercontent.com/mikhbur/conformer/master/conformer.sh &> /dev/null;
#chmod +x conformer.sh;
#wget --timeout=4 -qO- https://github.com/mikhbur/conformer/tree/master/modules -O TODOWNLOAD;
#rm -r modules;
#mkdir modules;
#for i in $(cat TODOWNLOAD | tr ' ' '/' | tr '"' '/' | cut -d "/" -f 25 |  grep ".sh"); do
#wget https://raw.githubusercontent.com/mikhbur/conformer/master/modules/$i -O modules/$i &> /dev/null;
#done
#rm TODOWNLOAD;

elif [[ $(echo "$1" | tr '[:upper:]' '[:lower:]') == "help" ]] || [[ $(echo "$1" | tr '[:upper:]' '[:lower:]') == "--help" ]] || [[ $(echo "$1" | tr '[:upper:]' '[:lower:]')  == "-h" ]]; then
Help_banner "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

#Wgets the host parameter. Checks host is up, has a webserver, using SSL/TLS.
elif [ "$1" != "" ]; then
	if [[ $(echo "$5" | tr '[:upper:]' '[:lower:]' ) == "disable_check" ]] || [[ $(echo "$6" | tr '[:upper:]' '[:lower:]') == "disable_check" ]] || [[ $(echo "$7" | tr '[:upper:]' '[:lower:]') == "disable_check" ]] || [[ $(echo "$8" | tr '[:upper:]' '[:lower:]') == "disable_check" ]] ; then
	:
	else
	#host_check=$(wget --timeout=4 -qO- https://$1 --no-check-certificate);
	host_check=$(curl -i -s -k  -X $'GET' \
	    -H $'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:45.0) Gecko/20100101 Firefox/45.0' \
	    $'https://'$1'/');
	if [[ "$host_check" != "" ]]; then
	:
	else
		PING_CHECK=$(ping -c 1 -t 8 -W 1 -i 0.2 "$1" 2>/dev/null);
		if [[ $PING_CHECK != *"64 bytes from"* ]] ; then
			echo "Invalid Host, or check your internet connection.";
			echo "Exiting...";
			exit 1;
		else
		:
		fi
	fi
fi


#Checks if parameter 2 username file or username entered
if [ "$2" == "" ]; then

echo "no username/file entered.";
echo "Exiting...";
exit 1;
fi

#Checks if a Password was entered or not.
if [ "$3" == "" ]; then
echo "Invalid Password.";
echo "Exiting...";
exit 1;
fi

MAINPOST "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

fi
}

MAINPOST(){

#Checks if any parameters were entered.
if [ "$1" != "" ]; then

if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "ciscosslvpn" ]]; then
	check_ciscoSSLVPN "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "netscaler" ]]; then
	check_Netscaler "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "owa" ]]; then
	check_OWA2016 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "sonicwallvoffice" ]]; then
	check_SonicWallVOffice "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "paloalto" ]]; then
	check_PaloAlto "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "sharepoint" ]]; then
	check_SharePoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "xenmobile" ]]; then
	check_XenMobile "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "xenapp" ]]; then
	check_XenApp "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "okta" ]]; then
	check_Okta "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "auto" ]]; then
	check_Start "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "smb" ]]; then
	SMB_CHECK "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
	:
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
	:
else
	echo "Invalid Module.";
	echo "Exiting...";
	exit 1;
fi
fi
LOG_YES=false;
LOG=/tmp/conformer.log;
#Determine if Logging, and where to log
if [[ $(echo "$5" | tr '[:upper:]' '[:lower:]') == "log="* ]] || [[ $(echo "$6" | tr '[:upper:]' '[:lower:]') == "log="* ]] || [[ $(echo "$7" | tr '[:upper:]' '[:lower:]') == "log="* ]] || [[ $(echo "$8" | tr '[:upper:]' '[:lower:]') == "log="* ]]; then
LOG_YES=true;
LOG=$(echo "$5" | grep -i log | cut -d "=" -f 2);
	if [[ "$LOG" == "" ]] ; then
		LOG=$(echo "$6" | grep -i log | cut -d "=" -f 2);
		if [[ "$LOG" == "" ]] ; then
			LOG=$(echo "$7" | grep -i log | cut -d "=" -f 2);
			if [[ "$LOG" == "" ]] ; then
				LOG=$(echo "$8" | grep -i log | cut -d "=" -f 2);
			fi
		fi
	fi
if [[ -d "$LOG" ]] ; then
	LOG_YES=false;
fi

fi


DEBUG_YES=false;
DEBUG=/tmp/conformer.debug;
#Determine if Debuging, and where to debug to.
if [[ $(echo "$5" | tr '[:upper:]' '[:lower:]') == "debug="* ]] || [[ $(echo "$6" | tr '[:upper:]' '[:lower:]') == "debug="* ]] || [[ $(echo "$7" | tr '[:upper:]' '[:lower:]') == "debug="* ]] || [[ $(echo "$8" | tr '[:upper:]' '[:lower:]') == "debug="* ]]; then
DEBUG_YES=true;
DEBUG=$(echo "$5" | grep -i debug | cut -d "=" -f 2);
	if [[ "$DEBUG" == "" ]] ; then
		DEBUG=$(echo "$6" | grep -i debug | cut -d "=" -f 2);
		if [[ "$DEBUG" == "" ]] ; then
			DEBUG=$(echo "$7" | grep -i debug | cut -d "=" -f 2);
			if [[ "$DEBUG" == "" ]] ; then
				DEBUG=$(echo "$8" | grep -i debug | cut -d "=" -f 2);
			fi
		fi
	fi
if [[ -d "$DEBUG" ]] ; then
	DEBUG_YES=false;
fi
fi

echo "";
if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "ciscosslvpn" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "netscaler" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "xenmobile" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "sonicwallvoffice" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "paloalto" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "owa" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "sharepoint" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "okta" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "xenapp" ]] || [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "smb" ]] ; then
echo "Host: $1";
if [[ $LOG_YES == true ]]; then
	echo "Host: $1" >> "$LOG";
fi
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
echo "Host: mail.google.com";
if [[ $LOG_YES == true ]]; then
	echo "Host: mail.google.com" >> "$LOG";
fi
elif [[ $(echo "$4" | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
echo "Host: outlook.office.com";
if [[ $LOG_YES == true ]] ; then
	echo "Host: outlook.office.com" >> "$LOG";
fi
fi

#Determine number of threads
com=0;
THREAD=1;
if [[ $(echo "$5" | tr '[:upper:]' '[:lower:]') == "thread="* ]] || [[ $(echo "$6" | tr '[:upper:]' '[:lower:]') == "thread="* ]] || [[ $(echo "$7" | tr '[:upper:]' '[:lower:]') == "thread="* ]] || [[ $(echo "$8" | tr '[:upper:]' '[:lower:]') == "thread="* ]]; then #Threaded
THREAD=$(echo "$5" | tr '[:upper:]' '[:lower:]' | grep thread | cut -d "=" -f 2);
	if [[ "$THREAD" == "" ]] ; then
		THREAD=$(echo "$6" | tr '[:upper:]' '[:lower:]' | grep thread | cut -d "=" -f 2);
		if [[ "$THREAD" == "" ]] ; then
			THREAD=$(echo "$7" | tr '[:upper:]' '[:lower:]' | grep thread | cut -d "=" -f 2);
			if [[ "$THREAD" == "" ]] ; then
				THREAD=$(echo "$8" | tr '[:upper:]' '[:lower:]' | grep thread | cut -d "=" -f 2);
			fi
		fi
	fi
fi

#Determine if/how long sleep
Sleep=0;
if [[ $(echo "$5" | tr '[:upper:]' '[:lower:]') == "sleep="* ]] || [[ $(echo "$6" | tr '[:upper:]' '[:lower:]') == "sleep="* ]] || [[ $(echo "$7" | tr '[:upper:]' '[:lower:]') == "sleep="* ]] || [[ $(echo "$8" | tr '[:upper:]' '[:lower:]') == "sleep="* ]]; then
Sleep=$(echo "$5" | tr '[:upper:]' '[:lower:]' | grep "sleep" | cut -d "=" -f 2);
	if [[ "$Sleep" == "" ]] ; then
		Sleep=$(echo "$6" | tr '[:upper:]' '[:lower:]' | grep "sleep" | cut -d "=" -f 2);
		if [[ "$Sleep" == "" ]] ; then
			Sleep=$(echo "$7" | tr '[:upper:]' '[:lower:]' | grep "sleep" | cut -d "=" -f 2);
			if [[ "$Sleep" == "" ]] ; then
				Sleep=$(echo "$8" | tr '[:upper:]' '[:lower:]' | grep "sleep" | cut -d "=" -f 2);
			fi
		fi
	fi
fi

#Determine if username file or username?
if [ ! -f "$2" ]; then
#Determine if password file or password?
if [ ! -f "$3" ]; then

line=$2;
pass=$3;
if [ "$pass" == "@SAME@" ]; then
pass=$2;
fi
if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "ciscosslvpn" ]]; then
	POST_ciscoSSLVPN "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "netscaler" ]]; then
	POST_Netscaler "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "owa" ]]; then
	POST_OWA2016 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
	POST_Gmail "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
	POST_Office365 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";

elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sonicwallvoffice" ]]; then
	POST_SonicWallVOffice "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "paloalto" ]]; then
	POST_PaloAlto "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sharepoint" ]]; then
	POST_SharePoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenmobile" ]]; then
	POST_XenMobile "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenapp" ]]; then
	POST_XenApp "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "okta" ]]; then
	POST_Okta "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "smb" ]]; then
	SMB_AUTH "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
fi

else  #Username + Password File
line=$2;

#combo file
if [[ $(echo "$2" | tr '[:upper:]' '[:lower:]') == "combo" ]] ; then

	for i in $(cat $3); do
		com=$((com+1));
		line=$(echo "$i" | cut -d ":" -f 2);
		pass=$(echo "$i" | cut -d ":" -f 3);

		if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "ciscosslvpn" ]]; then
			POST_ciscoSSLVPN "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "netscaler" ]]; then
			POST_Netscaler "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "owa" ]]; then
			POST_OWA2016 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
	
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
			POST_Gmail "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
			POST_Office365 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sonicwallvoffice" ]]; then
			POST_SonicWallVOffice "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "paloalto" ]]; then
			POST_PaloAlto "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sharepoint" ]]; then
			POST_SharePoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenmobile" ]]; then
			POST_XenMobile "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenapp" ]]; then
			POST_XenApp "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "okta" ]]; then
			POST_Okta "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "smb" ]]; then
			SMB_AUTH "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		fi
		if [[ $com == $THREAD ]] ; then
		wait $!;
		com=0;
		fi

		sleep "$Sleep"s;

	done
	wait;

else

	for pass in $(cat $3); do
		com=$((com+1));
		if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "ciscosslvpn" ]]; then
			POST_ciscoSSLVPN "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "netscaler" ]]; then
			POST_Netscaler "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "owa" ]]; then
			POST_OWA2016 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
	
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
			POST_Gmail "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
			POST_Office365 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sonicwallvoffice" ]]; then
			POST_SonicWallVOffice "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "paloalto" ]]; then
			POST_PaloAlto "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sharepoint" ]]; then
			POST_SharePoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenmobile" ]]; then
			POST_XenMobile "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenapp" ]]; then
			POST_XenApp "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "okta" ]]; then
			POST_Okta "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "smb" ]]; then
			SMB_AUTH "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		fi
		if [[ $com == $THREAD ]] ; then
		wait $!;
		com=0;
		fi

		sleep "$Sleep"s;


	done
	wait;
fi
fi

#Userlist
else

if [ ! -f "$3" ]; then

	for line in $(cat $2); do
		com=$((com+1));
		pass=$3;
		if [ "$pass" == "@SAME@" ]; then
		pass=$line;
		fi
		
		if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "ciscosslvpn" ]]; then
			POST_ciscoSSLVPN "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "netscaler" ]]; then
			POST_Netscaler "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "owa" ]]; then
			POST_OWA2016 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
	
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
			POST_Gmail "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
			POST_Office365 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sonicwallvoffice" ]]; then
			POST_SonicWallVOffice "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &

		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "paloalto" ]]; then
			POST_PaloAlto "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sharepoint" ]]; then
			POST_SharePoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenmobile" ]]; then
			POST_XenMobile "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenapp" ]]; then
			POST_XenApp "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "okta" ]]; then
			POST_Okta "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "smb" ]]; then
			SMB_AUTH "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		fi
		if [[ $com == $THREAD ]] ; then
		wait $! 2> /dev/null;
		com=0;
		fi

		sleep "$Sleep"s;

	done
	wait;

#userlist with passwordlist
else
	for line in $(cat $2); do
		for pass in $(cat $3); do
		com=$((com+1));
		if [[ $(echo "$4" | tr '[:upper:]' '[:lower:]')  == "ciscosslvpn" ]]; then
			POST_ciscoSSLVPN "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "netscaler" ]]; then
			POST_Netscaler "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "owa" ]]; then
			POST_OWA2016 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "gmail" ]]; then
			POST_Gmail "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "office365" ]]; then
			POST_Office365 "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sonicwallvoffice" ]]; then
			POST_SonicWallVOffice "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "paloalto" ]]; then
			POST_PaloAlto "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "sharepoint" ]]; then
			POST_SharePoint "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenmobile" ]]; then
			POST_XenMobile "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "xenmobile" ]]; then
			POST_XenApp "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "okta" ]]; then
			POST_Okta "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		elif [[ $(echo "$4"  | tr '[:upper:]' '[:lower:]') == "smb" ]]; then
			SMB_AUTH "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" &
		fi
		if [[ $com == $THREAD ]] ; then
		wait $!;
		com=0;
		fi

		sleep "$Sleep"s;

	done
	wait
done
fi

fi
}


#checks if parameters present
#program execution begins here.
if [ "$1" == "" ]; then
Help_banner;
fi
parameter_check "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8";
