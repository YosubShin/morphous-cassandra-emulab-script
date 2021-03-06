#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-22 Yosub       Initial version
# 2014-09-10 Yosub       Inspect Cassandra's running status after deploy

CASSANDRA_SRC_DIR_NAME=apache-cassandra-2.0.8-src-0713
CASSANDRA_SRC_TAR_FILE=cassandra-src.tar.gz
REMOTE_BASE_DIR=/scratch/ISS/shin14/repos
REMOTE_SCRIPT_DIR=$REMOTE_BASE_DIR/morphous-cassandra-emulab-script
REMOTE_REDEPLOY_SCRIPT=$REMOTE_SCRIPT_DIR/redeploy-node-script.sh
CASSANDRA_HOME=/opt/cassandra

MODE="soft"
if [ ! -z "$1" ]
then
    MODE=$1
fi

if [ ! -z "$2" ]
then
    CLUSTER_SIZE=$2
fi

echo "## Deploying Cassandra cluster with mode: " $MODE

# Set JAVA_HOME to build with Ant
export JAVA_HOME=/usr/lib/jvm/jdk1.7.0

cd $REMOTE_BASE_DIR
if [ -f "$REMOTE_BASE_DIR/$CASSANDRA_SRC_TAR_FILE" ]; then
    echo "## Unzipping Cassandra source"
    # Delete preexisting Cassandra source directory
    rm -rf $REMOTE_BASE_DIR/$CASSANDRA_SRC_DIR_NAME
    tar -xzf $CASSANDRA_SRC_TAR_FILE
    # Clean up tar file
    rm $CASSANDRA_SRC_TAR_FILE
else
    echo "## Downloading Cassandra source from Git repository"
    git clone https://github.com/YosubShin/morphous-cassandra.git
    mv morphous-cassandra $CASSANDRA_SRC_DIR_NAME
fi

cd $REMOTE_BASE_DIR/$CASSANDRA_SRC_DIR_NAME

echo "## Building Cassandra source"
rm -rf build
ant clean build

echo "## Ant Build is over. Invoking redeploy script on remote nodes"

# Invoke redeploy script for each node, parallelize after node-0
for (( i=0; i < CLUSTER_SIZE; i++))
do
if [ $i == 0 ]; then
    echo "## Invoking redeploy script on node-$i"
    ssh -o "StrictHostKeyChecking no" node-$i "sudo $REMOTE_REDEPLOY_SCRIPT node-$i $MODE"
    echo "## Finished invoking redeploy script on node-$i"
else
    (
    echo "## Invoking redeploy script on node-$i"
    ssh -o "StrictHostKeyChecking no" node-$i "sudo $REMOTE_REDEPLOY_SCRIPT node-$i $MODE"
    echo "## Finished invoking redeploy script on node-$i"
    ) &
fi
done

wait

sleep 10

$CASSANDRA_HOME/bin/nodetool status
