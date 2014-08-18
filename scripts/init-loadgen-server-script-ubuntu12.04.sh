#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-18 Yosub       Copied from node server init script

# Install necessary binaries
echo "## Installing necessary binaries ..."

# Install Oracle Java 7
echo "## Installing Java ..."

JAVA_INSTALL_FILE=jdk-7u65-linux-x64.tar.gz
JAVA_INSTALL_DIR=/tmp
JAVA_INSTALL_PATH=$JAVA_INSTALL_DIR/$JAVA_INSTALL_FILE
if ! [ -f "$JAVA_INSTALL_PATH" ]
then
    echo "Java install file does not exists"
    sudo wget --directory-prefix=$JAVA_INSTALL_DIR --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u65-b17/$JAVA_INSTALL_FILE
else
    echo "Java install file already exists."
fi
sudo tar -xvf $JAVA_INSTALL_PATH -C $JAVA_INSTALL_DIR
sudo mkdir /usr/lib/jvm
sudo mv $JAVA_INSTALL_DIR/jdk1.7* /usr/lib/jvm/jdk1.7.0
sudo update-alternatives --install "/usr/bin/java" "java" "/usr/lib/jvm/jdk1.7.0/bin/java" 1
sudo update-alternatives --install "/usr/bin/javac" "javac" "/usr/lib/jvm/jdk1.7.0/bin/javac" 1
sudo update-alternatives --install "/usr/bin/javaws" "javaws" "/usr/lib/jvm/jdk1.7.0/bin/javaws" 1
sudo chmod a+x /usr/bin/java
sudo chmod a+x /usr/bin/javac
sudo chmod a+x /usr/bin/javaws

SCRIPT_PATH=/scratch/ISS/shin14/repos/morphous-cassandra-emulab-script/scripts
# Git pull
cd SCRIPT_PATH
git pull

