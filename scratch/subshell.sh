#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-19 Yosub       Initial version

CLUSTER_SIZE=10
CASSANDRA_SRC_DIR_BASE=/Users/Daniel/Dropbox/Illinois/research/repos
CASSANDRA_SRC_DIR_NAME=apache-cassandra-2.0.8-src-0713
CASSANDRA_SRC_DIR=$CASSANDRA_SRC_DIR_BASE/$CASSANDRA_SRC_DIR_NAME
CASSANDRA_SRC_TAR_FILE=cassandra-src.tar.gz
SSH_USER=yossupp
SSH_URL=node-0.cassandra-morphous.ISS.emulab.net
REMOTE_BASE_DIR=/scratch/ISS/shin14/repos
REMOTE_SCRIPT_DIR=$REMOTE_BASE_DIR/morphous-cassandra-emulab-script
REMOTE_REDEPLOY_SCRIPT=$REMOTE_SCRIPT_DIR/redeploy-node-script.sh


# Invoke redeploy script for each node
for (( i=0; i < CLUSTER_SIZE; i++))
do  
if [ $i == 0 ]; then
    echo "## Invoking redeploy script on node-$i"
    sleep 5
    echo "## Finished redeploy script on node-$i"
else
    (echo "## Invoking redeploy script on node-$i"
    sleep 5
    echo "## Finished redeploy script on node-$i") &
fi
done

