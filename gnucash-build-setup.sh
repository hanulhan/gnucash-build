#!/bin/bash -eux

MOUNTPOINT=/mnt/s3
TARGET=gnucash-build
PATH_TO_FILE=/home/uli/Project/$TARGET
PATH_TO_SCRIPT=$PATH_TO_FILE/$TARGET.sh
LOGFILE=$PATH_TO_FILE/$TARGET.log
UPDATE_STATE_FILE=$PATH_TO_FILE/update-state.txt
KEYSTORE_FILE=$PATH_TO_FILE/Tomcat/acentic.neu.keystore
WAR_FILE=ACS.war
TOMCAT7_USER_ID=120
TOMCAT7_GROUP_ID=120


export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical


exec >> $LOGFILE 2>&1

PATH=$PATH:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:


# Function do set the update state to a file
function setUpdateState {
   UPDATE_STATE=$1
   doLog "Set the update State to $1"
   echo $UPDATE_STATE > $UPDATE_STATE_FILE
}

function doLog {
   echo $1
   #echo $1 >> $LOGFILE
}

function doLogUpdateState {
    doLog "########## $1 ##########"
}

function package_exists() {
    dpkg -s $1 &> /dev/null
    return $?    
}

#Check if Logfile already exists. 
if [ ! -f $LOGFILE ];
then
   touch $LOGFILE
   doLog "Start script"
else
   doLog "Restart script"
fi


#Check if the update-state-file already exists
if [ ! -f $UPDATE_STATE_FILE ];
then
    doLog "UpdateState file does not exists. Create it"
    touch $UPDATE_STATE_FILE
    setUpdateState 1
else
    UPDATE_STATE=$(< ${UPDATE_STATE_FILE})
    doLog "UpdateState= $UPDATE_STATE"
fi





case $UPDATE_STATE in


1) #Installation step 1. Update packages
   doLogUpdateState "UPDATE-STATE 1: Update packages list"

   # get the ubuntu package list
   apt-get -y update
   sleep 5
   doLog "==> Performing upgrade (all packages and kernel)"
   apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" upgrade
   sleep 5

   doLog "==> Performing dist-upgrade (all packages and kernel)"
   apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" dist-upgrade
   sleep 5

   apt-get -y autoremove

   doLog "==> Finished apt-get upgrade. Reboot now"
   setUpdateState 2
   #reboot
   ;&

2) # Installation step 2
   doLogUpdateState "UPDATE-STATE 2"

   if ! package_exists openjdk-8-jdk; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install openjdk-8-jdk
   fi
   
   setUpdateState 3
   ;&   # Fall through


3) # Installation step 3
   setUpdateState 4
   ;&   # Fall through

4) # Installation step 4: Ubuntu installation 3

   doLogUpdateState "UPDATE-STATE 4"
  
   setUpdateState 5
   ;&   # Fall through


5) # Installation step 5

   doLogUpdateState "UPDATE-STATE 5: Ubuntu installation 4"
   
   setUpdateState 6
   ;&      # Fall through


6) # Installation step 6:

   doLogUpdateState "UPDATE-STATE 6a"
   
   setUpdateState 7
   ;&      # Fall through

7) # Installation step 7: Mysql-client

   doLogUpdateState "UPDATE-STATE 7: 2.11 Mysql-client skipped"

   setUpdateState 8
   ;&      # Fall through

8) # Install Tomcat7

   doLogUpdateState "UPDATE-STATE 8: 3.1 Tomcat7 installation"

   
   if ! package_exists tomcat7; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install tomcat7
   fi
   setUpdateState 9
   ;&      # Fall through


9) # Setup Tomcat7

   doLogUpdateState "UPDATE-STATE 9"

   setUpdateState 10
   ;&      # Fall through

10)
   doLogUpdateState "UPDATE-State 10"

   setUpdateState 99
   ;&

99)
   doLogUpdateState "UPDATE-STATE 99"

   setUpdateState 100
   ;&
   
   
100)

   touch $PATH_TO_FILE/UPDATE_FINISHED
   ;;

esac



















