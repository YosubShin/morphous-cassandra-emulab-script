#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-19 Yosub       Initial version

CLUSTER_SIZE=10
CASSANDRA_SRC_DIR_BASE=/Users/Daniel/Dropbox/Illinois/research/repos
CASSANDRA_SRC_DIR_NAME=apache-apache-cassandra-2.0.8-src-0713
CASSANDRA_SRC_DIR=$CASSANDRA_SRC_DIR_BASE/$CASSANDRA_SRC_DIR_NAME
CASSANDRA_SRC_TAR_FILE=cassandra-src.tar.gz
SCP_USER=yossupp
SCP_URL=node-0.cassandra-morphous.ISS.emulab.net
REMOTE_BASE_DIR=/scratch/ISS/shin14/repos
REMOTE_SCRIPT_DIR=$REMOTE_BASE_DIR/morphous-cassandra-emulab-script
REMOTE_REDEPLOY_SCRIPT=$REMOTE_SCRIPT_DIR/redeploy-node-script.sh

: ${JAVA_HOME=/usr/lib/jvm/jdk1.7.0}

tar -czf $CASSANDRA_SRC_TAR_FILE $CASSANDRA_SRC_DIR
ssh $SCP_USER@$SCP_URL <<EOF
# Clear out previously existing Cassandra source files
rm -rf $REMOTE_BASE_DIR/$CASSANDRA_SRC_DIR_NAME
EOF

scp $CASSANDRA_SRC_TAR_FILE $SCP_USER@$SCP_URL:$REMOTE_BASE_DIR

ssh $SCP_USER@$SCP_URL <<EOF
# Now in remote machine's shell
cd $REMOTE_BASE_DIR
tar -xzf $CASSANDRA_SRC_TAR_FILE
cd $CASSANDRA_SRC_DIR_NAME
ant build

# Invoke redeploy script for each node
for (( i=0; i<$CLUSER_SIZE; i++))
do
ssh -o "StrictHostKeyChecking no" node-$i "sudo $REMOTE_REDEPLOY_SCRIPT node-$i"
done

EOF
