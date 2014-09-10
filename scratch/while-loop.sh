#!/bin/bash

CLUSTER_SIZE=8

cat while-loop-test-input.txt | grep 10.1.1 | {
    while IFS= read -r line
    do
        ((nodeNum++))
        if echo "$line" | grep -q "UN"; then
            ((activeCount++))
        else
            echo "## Node " $nodeNum " failed to start up"
        fi
    done
    if [ $activeCount -lt $CLUSTER_SIZE ]; then
        echo "Cassandra cluster failed to deploy. Expected=" $CLUSTER_SIZE " Deployed=" $activeCount
    else
        echo "## Finished invoking redeploy scripts on all nodes."
    fi
}


