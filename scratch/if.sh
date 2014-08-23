#!/bin/bash
NODE_ADDRESS=$1

if [ $NODE_ADDRESS == "node-0" ]; then
    echo "## Executing deploy Cassandra script..."
    /scratch/ISS/shin14/repos/morphous-cassandra-emulab-script/deploy-cassandra-cluster.sh
fi
