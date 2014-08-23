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

echo "## Archiving Cassandra source files..."
tar -czf $CASSANDRA_SRC_TAR_FILE -C $CASSANDRA_SRC_DIR_BASE $CASSANDRA_SRC_DIR_NAME

echo "## Deleting remote host's Cassandra source files"
ssh -T $SSH_USER@$SSH_URL /bin/bash << EOF
# Clear out previously existing Cassandra source files
sudo rm -rf $REMOTE_BASE_DIR/$CASSANDRA_SRC_DIR_NAME
sudo rm $REMOTE_BASE_DIR/$CASSANDRA_SRC_TAR_FILE
EOF

echo "## Uploading archived Cassandra source to remote host"
scp $CASSANDRA_SRC_TAR_FILE $SSH_USER@$SSH_URL:$REMOTE_BASE_DIR

# Clean up tar file
rm $CASSANDRA_SRC_TAR_FILE

echo "## Executing cluster redeploy script on remote host"
ssh -T $SSH_USER@$SSH_URL "setenv REMOTE_BASE_DIR $REMOTE_BASE_DIR; setenv CASSANDRA_SRC_TAR_FILE $CASSANDRA_SRC_TAR_FILE; setenv CASSANDRA_SRC_DIR_NAME $CASSANDRA_SRC_DIR_NAME; setenv CLUSTER_SIZE $CLUSTER_SIZE; setenv REMOTE_REDEPLOY_SCRIPT $REMOTE_REDEPLOY_SCRIPT; /bin/bash" << 'EOF'
# Now in remote machine's shell
# Set JAVA_HOME to build with Ant
export JAVA_HOME=/usr/lib/jvm/jdk1.7.0

echo "## Unzipping Cassandra source"
cd $REMOTE_BASE_DIR
tar -xzf $CASSANDRA_SRC_TAR_FILE

# Clean up tar file
rm $CASSANDRA_SRC_TAR_FILE

cd $REMOTE_BASE_DIR/$CASSANDRA_SRC_DIR_NAME

echo "## Building Cassandra source"
ant build

# Invoke redeploy script for each node
for (( i=0; i < CLUSTER_SIZE; i++))
do
echo "## Invoking redeploy script on node-$i"
ssh -T -o "StrictHostKeyChecking no" node-$i "sudo $REMOTE_REDEPLOY_SCRIPT node-$i"
done

EOF
