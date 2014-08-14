#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-01 Yosub       Initial version

CASSANDRA_PATH=/scratch

# Install necessary binaries
echo "## Installing necessary binaries ..."
/usr/bin/yum -y install ant

# Install Oracle Java 7
echo "## Installing Java ..."

JAVA_INSTALL_FILE=jdk-7u65-linux-x64.rpm
JAVA_INSTALL_DIR=/opt
JAVA_INSTALL_PATH=$JAVA_INSTALL_DIR/$JAVA_INSTALL_FILE
if ! [ -f "$JAVA_INSTALL_PATH" ]
then
    echo "RPM file does not exists"
    wget --directory-prefix=$JAVA_INSTALL_DIR --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u65-b17/$JAVA_INSTALL_FILE
else
    echo "RPM file already exists."
fi
rpm -Uvh $JAVA_INSTALL_PATH

alternatives --install /usr/bin/java java /usr/java/latest/jre/bin/java 200000
alternatives --install /usr/bin/javaws javaws /usr/java/latest/jre/bin/javaws 200000
alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 200000

export JAVA_HOME=/usr/java/latest
export PATH=$PATH:$JAVA_HOME/bin/

# Setup necessary directories used by Apache Cassandra
echo "## Creating directories for Apache Cassandra"
rm -rf /var/lib/cassandra
rm -rf /var/log/cassandra
mkdir --mode=777 /var/lib/cassandra
mkdir --mode=777 /var/lib/cassandra/data
mkdir --mode=777 /var/lib/cassandra/commitlog
mkdir --mode=777 /var/lib/cassandra/saved_caches
mkdir --mode=777 /var/log/cassandra

# Setup ports used by Apache Cassndra
echo "## Setting up ports used by Apache Cassandra"
iptables -A INPUT -p tcp --dport 7000 -j ACCEPT
iptables -A INPUT -p tcp --dport 9160 -j ACCEPT

# Copy Cassandra to local machine
echo "## Copying Cassandra to local machine"
NODE_ADDRESS="$HOST"
#NODE_ADDRESS=node-0
echo "NODE ADDRESS : $NODE_ADDRESS"
CASSANDRA_HOME=/opt/cassandra
if [ -d "$CASSANDRA_HOME" ]
then
    cd $CASSANDRA_HOME
    git pull
else
    rm -rf $CASSANDRA_HOME
    git clone https://github.com/YosubShin/morphous-cassandra.git --branch emulab $CASSANDRA_HOME
fi
# Replace conf/cassandra.yaml file's listen_address with the current node's name
sed -i "s/^listen_address: .*/listen_address: $NODE_ADDRESS/" $CASSANDRA_HOME/conf/cassandra.yaml

# Start up Cassandra
echo "## Starting Apache Cassandra"
#$CASSANDRA_HOME/bin/cassandra
