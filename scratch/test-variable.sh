#!/bin/bash

i="This is local i"
local1='"Local variable 1"'

ssh -T yossupp@node-0.cassandra-morphous.ISS.emulab.net "setenv k $local1; /bin/bash" << 'EOF'
# Now in remote machine's shell

echo "i should not be printed, since it's local"
echo $i

echo "Should print 0 through 9."
for (( j=0; j < 10; j++))
do
echo $j
done

echo "$k"

EOF
