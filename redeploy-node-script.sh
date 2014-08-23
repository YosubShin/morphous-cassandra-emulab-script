#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-20 Yosub       Initial version

NODE_ADDRESS=$1
CASSANDRA_SRC_DIR_NAME=apache-cassandra-2.0.8-src-0713
REMOTE_BASE_DIR=/scratch/ISS/shin14/repos
CASSANDRA_HOME=/opt/cassandra

echo "##(Re)Deploying Cassandra Node on $NODE_ADDRESS"

# Set JAVA_HOME to run Cassandra
export JAVA_HOME=/usr/lib/jvm/jdk1.7.0

if [ $# -lt 1 ]
then
    echo $"Usage: $0 <hostname> [<mode>]"
    exit 2
fi

MODE="soft"
if [ ! -z "$2" ]
then
    MODE = $2
fi

echo "## Killing & Deleting existing Cassandra node"
if [ -d "$CASSANDRA_HOME" ]
then
    sudo pkill -f CassandraDaemon
    sleep 5

    if [ "$MODE" == "hard" ]
    then
        echo "## Removing and then creating directories for Apache Cassandra"
        sudo rm -rf /var/lib/cassandra
        sudo rm -rf /var/log/cassandra
        sudo mkdir --mode=777 /var/lib/cassandra
        sudo mkdir --mode=777 /var/lib/cassandra/data
        sudo mkdir --mode=777 /var/lib/cassandra/commitlog
        sudo mkdir --mode=777 /var/lib/cassandra/saved_caches
        sudo mkdir --mode=777 /var/log/cassandra
    fi

    sudo rm -rf $CASSANDRA_HOME
else
    echo "## Creating directories for Cassandra's data & log"
    sudo mkdir --mode=777 /var/lib/cassandra
    sudo mkdir --mode=777 /var/lib/cassandra/data
    sudo mkdir --mode=777 /var/lib/cassandra/commitlog
    sudo mkdir --mode=777 /var/lib/cassandra/saved_caches
    sudo mkdir --mode=777 /var/log/cassandra
fi

echo "## Copying Cassandra to local machine"
sudo mkdir $CASSANDRA_HOME
sudo cp -r $REMOTE_BASE_DIR/$CASSANDRA_SRC_DIR_NAME/* $CASSANDRA_HOME/

echo "## Executing Cassandra"
sudo $CASSANDRA_HOME/bin/cassandra
