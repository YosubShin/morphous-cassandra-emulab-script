#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-01 Yosub       Initial version
# 2014-08-14 Yosub       Embedded cassandra.yaml
# 2014-08-22 Yosub       Modularize
# 2014-08-26 Yosub       Fix minor bugs

NODE_ADDRESS=$1

if [ $# -ne 1 ]
then
    echo $"Usage: $0 <hostname>"
    exit 2
fi

CASSANDRA_PATH=/scratch

# Install necessary binaries
echo "## Installing necessary binaries ..."
sudo apt-get update
sudo apt-get install ant -y

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

sudo update-alternatives --set java /usr/lib/jvm/jdk1.7.0/bin/java

if [ $NODE_ADDRESS == "node-0" ]; then
    echo "## Executing deploy Cassandra script..."
    /scratch/ISS/shin14/repos/morphous-cassandra-emulab-script/deploy-cassandra-cluster.sh
fi
