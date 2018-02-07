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
   if ! package_exists intltool; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install intltool
   fi
   ;&   # Fall through

4) # Installation step 4: Ubuntu installation 3

   doLogUpdateState "UPDATE-STATE 4"
   if ! package_exists autoconf; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install autoconf
   fi
   if ! package_exists automake; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install automake
   fi
   if ! package_exists autotools-dev; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install autotools-dev
   fi
   if ! package_exists libsigsegv2; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install libsigsegv2
   fi
   if ! package_exists m4; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install m4
   fi
   setUpdateState 5
   ;&   # Fall through


5) # Installation step 5

   doLogUpdateState "UPDATE-STATE 5: Ubuntu installation 4"
   if ! package_exists libtool; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install libtool
   fi
   if ! package_exists libltdl-dev; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install libltdl-dev
   fi
   
   setUpdateState 6
   ;&      # Fall through


6) # Installation step 6:

   doLogUpdateState "UPDATE-STATE 6"
   if ! package_exists libglib2.0-dev; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install libglib2.0-dev
   fi
   
   setUpdateState 7
   ;&      # Fall through

7) # Installation step 7: Mysql-client

   doLogUpdateState "UPDATE-STATE 7"
   PACKAGE=icu-devtools
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi

   PACKAGE=libicu-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi

   setUpdateState 8
   ;&      # Fall through

8) # Install Tomcat7

   doLogUpdateState "UPDATE-STATE 8"


   PACKAGE=libboost-all-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   
   setUpdateState 9
   ;&      # Fall through


9) # Setup Tomcat7

   doLogUpdateState "UPDATE-STATE 9"


   PACKAGE=guile-2.0
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi

   PACKAGE=guile-2.0-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 10
   ;&      # Fall through

10)
   doLogUpdateState "UPDATE-State 10"

   PACKAGE=swig2.0
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 11
   ;&

11)
   doLogUpdateState "UPDATE-State 11"

   PACKAGE=libxml++2.6-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 12
   ;&

12)
   doLogUpdateState "UPDATE-State 12"

   PACKAGE=libxsltl-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 13
   ;&

13)
   doLogUpdateState "UPDATE-State 13"

   PACKAGE=xsltproc
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 14
   ;&

14)
   doLogUpdateState "UPDATE-State 14"

   PACKAGE=libgtest-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 15
   ;&

15)
   doLogUpdateState "UPDATE-State 15"

   PACKAGE=google-mock
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 16
   ;&

16)
   doLogUpdateState "UPDATE-State 16"

   PACKAGE=gtk+3.0
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 17
   ;&
17)
   doLogUpdateState "UPDATE-State 17"

   PACKAGE=libgtk3.0
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 18
   ;&

18)
   doLogUpdateState "UPDATE-State 18"

   PACKAGE=libwebkit2gtk-4.0-37
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 19
   ;&
19)
   doLogUpdateState "UPDATE-STATE 19"

   PACKAGE=libwebkit2gtk-4.0-dev
   if ! package_exists $PACKAGE; then
      apt-get -q -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install $PACKAGE
   fi
   setUpdateState 100
   ;&
   
   
100)

   touch $PATH_TO_FILE/UPDATE_FINISHED
   ;;

esac



















