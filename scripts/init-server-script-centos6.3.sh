#!/bin/bash
# DATE       AUTHOR      COMMENT
# ---------- ----------- -----------------------------------------------------
# 2014-08-01 Yosub       Initial version
# 2014-08-14 Yosub       Embedded cassandra.yaml
# 2014-08-16 Yosub       

NODE_ADDRESS=$1

if [ $# -ne 1 ]
then
    echo $"Usage: $0 <hostname>"
    exit 2
fi

CASSANDRA_PATH=/scratch

# Install necessary binaries
echo "## Installing necessary binaries ..."
sudo /usr/bin/yum -y install ant

# Install Oracle Java 7
echo "## Installing Java ..."

JAVA_INSTALL_FILE=jdk-7u65-linux-x64.rpm
JAVA_INSTALL_DIR=/opt
JAVA_INSTALL_PATH=$JAVA_INSTALL_DIR/$JAVA_INSTALL_FILE
if ! [ -f "$JAVA_INSTALL_PATH" ]
then
    echo "RPM file does not exists"
    sudo wget --directory-prefix=$JAVA_INSTALL_DIR --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/7u65-b17/$JAVA_INSTALL_FILE
else
    echo "RPM file already exists."
fi
sudo rpm -Uvh $JAVA_INSTALL_PATH

sudo alternatives --install /usr/bin/java java /usr/java/latest/jre/bin/java 200000
sudo alternatives --install /usr/bin/javaws javaws /usr/java/latest/jre/bin/javaws 200000
sudo alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
sudo alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 200000

sudo export JAVA_HOME=/usr/java/latest
sudo export PATH=$PATH:$JAVA_HOME/bin/

# Setup necessary directories used by Apache Cassandra
echo "## Creating directories for Apache Cassandra"
sudo rm -rf /var/lib/cassandra
sudo rm -rf /var/log/cassandra
sudo mkdir --mode=777 /var/lib/cassandra
sudo mkdir --mode=777 /var/lib/cassandra/data
sudo mkdir --mode=777 /var/lib/cassandra/commitlog
sudo mkdir --mode=777 /var/lib/cassandra/saved_caches
sudo mkdir --mode=777 /var/log/cassandra

# Setup ports used by Apache Cassndra
echo "## Setting up ports used by Apache Cassandra"
sudo iptables -A INPUT -p tcp --dport 7000 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 9160 -j ACCEPT

# Copy Cassandra to local machine
echo "## Copying Cassandra to local machine"
echo "NODE ADDRESS : $NODE_ADDRESS"
CASSANDRA_HOME=/opt/cassandra
if [ -d "$CASSANDRA_HOME" ]
then
    cd $CASSANDRA_HOME
    sudo git pull
else
    sudo rm -rf $CASSANDRA_HOME
    sudo git clone https://github.com/YosubShin/morphous-cassandra.git --branch emulab $CASSANDRA_HOME
fi
# Replace conf/cassandra.yaml file's listen_address with the current node's name
# sed -i "s/^listen_address: .*/listen_address: $NODE_ADDRESS/" $CASSANDRA_HOME/conf/cassandra.yaml
sudo cat > $CASSANDRA_HOME/conf/cassandra.yaml <<EOF
# Cassandra storage config YAML 

# NOTE:
#   See http://wiki.apache.org/cassandra/StorageConfiguration for
#   full explanations of configuration directives
# /NOTE

# The name of the cluster. This is mainly used to prevent machines in
# one logical cluster from joining another.
cluster_name: 'Test Cluster'

# This defines the number of tokens randomly assigned to this node on the ring
# The more tokens, relative to other nodes, the larger the proportion of data
# that this node will store. You probably want all nodes to have the same number
# of tokens assuming they have equal hardware capability.
#
# If you leave this unspecified, Cassandra will use the default of 1 token for legacy compatibility,
# and will use the initial_token as described below.
#
# Specifying initial_token will override this setting.
#
# If you already have a cluster with 1 token per node, and wish to migrate to 
# multiple tokens per node, see http://wiki.apache.org/cassandra/Operations
num_tokens: 256

# initial_token allows you to specify tokens manually.  While you can use # it with
# vnodes (num_tokens > 1, above) -- in which case you should provide a 
# comma-separated list -- it's primarily used when adding nodes # to legacy clusters 
# that do not have vnodes enabled.
# initial_token:

# May either be "true" or "false" to enable globally, or contain a list
# of data centers to enable per-datacenter.
# hinted_handoff_enabled: DC1,DC2
# See http://wiki.apache.org/cassandra/HintedHandoff
hinted_handoff_enabled: true
# this defines the maximum amount of time a dead host will have hints
# generated.  After it has been dead this long, new hints for it will not be
# created until it has been seen alive and gone down again.
max_hint_window_in_ms: 10800000 # 3 hours
# Maximum throttle in KBs per second, per delivery thread.  This will be
# reduced proportionally to the number of nodes in the cluster.  (If there
# are two nodes in the cluster, each delivery thread will use the maximum
# rate; if there are three, each will throttle to half of the maximum,
# since we expect two nodes to be delivering hints simultaneously.)
hinted_handoff_throttle_in_kb: 1024
# Number of threads with which to deliver hints;
# Consider increasing this number when you have multi-dc deployments, since
# cross-dc handoff tends to be slower
max_hints_delivery_threads: 2

# Maximum throttle in KBs per second, total. This will be
# reduced proportionally to the number of nodes in the cluster.
batchlog_replay_throttle_in_kb: 1024

# Authentication backend, implementing IAuthenticator; used to identify users
# Out of the box, Cassandra provides org.apache.cassandra.auth.{AllowAllAuthenticator,
# PasswordAuthenticator}.
#
# - AllowAllAuthenticator performs no checks - set it to disable authentication.
# - PasswordAuthenticator relies on username/password pairs to authenticate
#   users. It keeps usernames and hashed passwords in system_auth.credentials table.
#   Please increase system_auth keyspace replication factor if you use this authenticator.
authenticator: AllowAllAuthenticator

# Authorization backend, implementing IAuthorizer; used to limit access/provide permissions
# Out of the box, Cassandra provides org.apache.cassandra.auth.{AllowAllAuthorizer,
# CassandraAuthorizer}.
#
# - AllowAllAuthorizer allows any action to any user - set it to disable authorization.
# - CassandraAuthorizer stores permissions in system_auth.permissions table. Please
#   increase system_auth keyspace replication factor if you use this authorizer.
authorizer: AllowAllAuthorizer

# Validity period for permissions cache (fetching permissions can be an
# expensive operation depending on the authorizer, CassandraAuthorizer is
# one example). Defaults to 2000, set to 0 to disable.
# Will be disabled automatically for AllowAllAuthorizer.
permissions_validity_in_ms: 2000

# The partitioner is responsible for distributing groups of rows (by
# partition key) across nodes in the cluster.  You should leave this
# alone for new clusters.  The partitioner can NOT be changed without
# reloading all data, so when upgrading you should set this to the
# same partitioner you were already using.
#
# Besides Murmur3Partitioner, partitioners included for backwards
# compatibility include RandomPartitioner, ByteOrderedPartitioner, and
# OrderPreservingPartitioner.
#
partitioner: org.apache.cassandra.dht.Murmur3Partitioner

# Directories where Cassandra should store data on disk.  Cassandra
# will spread data evenly across them, subject to the granularity of
# the configured compaction strategy.
data_file_directories:
    - /var/lib/cassandra/data

# commit log
commitlog_directory: /var/lib/cassandra/commitlog

# policy for data disk failures:
# stop_paranoid: shut down gossip and Thrift even for single-sstable errors.
# stop: shut down gossip and Thrift, leaving the node effectively dead, but
#       can still be inspected via JMX.
# best_effort: stop using the failed disk and respond to requests based on
#              remaining available sstables.  This means you WILL see obsolete
#              data at CL.ONE!
# ignore: ignore fatal errors and let requests fail, as in pre-1.2 Cassandra
disk_failure_policy: stop

# policy for commit disk failures:
# stop: shut down gossip and Thrift, leaving the node effectively dead, but
#       can still be inspected via JMX.
# stop_commit: shutdown the commit log, letting writes collect but 
#              continuing to service reads, as in pre-2.0.5 Cassandra
# ignore: ignore fatal errors and let the batches fail
commit_failure_policy: stop

# Maximum size of the key cache in memory.
#
# Each key cache hit saves 1 seek and each row cache hit saves 2 seeks at the
# minimum, sometimes more. The key cache is fairly tiny for the amount of
# time it saves, so it's worthwhile to use it at large numbers.
# The row cache saves even more time, but must contain the entire row,
# so it is extremely space-intensive. It's best to only use the
# row cache if you have hot rows or static rows.
#
# NOTE: if you reduce the size, you may not get you hottest keys loaded on startup.
#
# Default value is empty to make it "auto" (min(5% of Heap (in MB), 100MB)). Set to 0 to disable key cache.
key_cache_size_in_mb:

# Duration in seconds after which Cassandra should
# save the key cache. Caches are saved to saved_caches_directory as
# specified in this configuration file.
#
# Saved caches greatly improve cold-start speeds, and is relatively cheap in
# terms of I/O for the key cache. Row cache saving is much more expensive and
# has limited use.
#
# Default is 14400 or 4 hours.
key_cache_save_period: 14400

# Number of keys from the key cache to save
# Disabled by default, meaning all keys are going to be saved
# key_cache_keys_to_save: 100

# Maximum size of the row cache in memory.
# NOTE: if you reduce the size, you may not get you hottest keys loaded on startup.
#
# Default value is 0, to disable row caching.
row_cache_size_in_mb: 0

# Duration in seconds after which Cassandra should
# safe the row cache. Caches are saved to saved_caches_directory as specified
# in this configuration file.
#
# Saved caches greatly improve cold-start speeds, and is relatively cheap in
# terms of I/O for the key cache. Row cache saving is much more expensive and
# has limited use.
#
# Default is 0 to disable saving the row cache.
row_cache_save_period: 0

# Number of keys from the row cache to save
# Disabled by default, meaning all keys are going to be saved
# row_cache_keys_to_save: 100

# The off-heap memory allocator.  Affects storage engine metadata as
# well as caches.  Experiments show that JEMAlloc saves some memory
# than the native GCC allocator (i.e., JEMalloc is more
# fragmentation-resistant).
# 
# Supported values are: NativeAllocator, JEMallocAllocator
#
# If you intend to use JEMallocAllocator you have to install JEMalloc as library and
# modify cassandra-env.sh as directed in the file.
#
# Defaults to NativeAllocator
# memory_allocator: NativeAllocator

# saved caches
saved_caches_directory: /var/lib/cassandra/saved_caches

# commitlog_sync may be either "periodic" or "batch." 
# When in batch mode, Cassandra won't ack writes until the commit log
# has been fsynced to disk.  It will wait up to
# commitlog_sync_batch_window_in_ms milliseconds for other writes, before
# performing the sync.
#
# commitlog_sync: batch
# commitlog_sync_batch_window_in_ms: 50
#
# the other option is "periodic" where writes may be acked immediately
# and the CommitLog is simply synced every commitlog_sync_period_in_ms
# milliseconds.  By default this allows 1024*(CPU cores) pending
# entries on the commitlog queue.  If you are writing very large blobs,
# you should reduce that; 16*cores works reasonably well for 1MB blobs.
# It should be at least as large as the concurrent_writes setting.
commitlog_sync: periodic
commitlog_sync_period_in_ms: 10000
# commitlog_periodic_queue_size:

# The size of the individual commitlog file segments.  A commitlog
# segment may be archived, deleted, or recycled once all the data
# in it (potentially from each columnfamily in the system) has been
# flushed to sstables.  
#
# The default size is 32, which is almost always fine, but if you are
# archiving commitlog segments (see commitlog_archiving.properties),
# then you probably want a finer granularity of archiving; 8 or 16 MB
# is reasonable.
commitlog_segment_size_in_mb: 32

# any class that implements the SeedProvider interface and has a
# constructor that takes a Map<String, String> of parameters will do.
seed_provider:
    # Addresses of hosts that are deemed contact points. 
    # Cassandra nodes use this list of hosts to find each other and learn
    # the topology of the ring.  You must change this if you are running
    # multiple nodes!
    - class_name: org.apache.cassandra.locator.SimpleSeedProvider
      parameters:
          # seeds is actually a comma-delimited list of addresses.
          # Ex: "<ip1>,<ip2>,<ip3>"
          - seeds: "node-0"

# For workloads with more data than can fit in memory, Cassandra's
# bottleneck will be reads that need to fetch data from
# disk. "concurrent_reads" should be set to (16 * number_of_drives) in
# order to allow the operations to enqueue low enough in the stack
# that the OS and drives can reorder them.
#
# On the other hand, since writes are almost never IO bound, the ideal
# number of "concurrent_writes" is dependent on the number of cores in
# your system; (8 * number_of_cores) is a good rule of thumb.
concurrent_reads: 32
concurrent_writes: 32

# Total memory to use for sstable-reading buffers.  Defaults to
# the smaller of 1/4 of heap or 512MB.
# file_cache_size_in_mb: 512

# Total memory to use for memtables.  Cassandra will flush the largest
# memtable when this much memory is used.
# If omitted, Cassandra will set it to 1/4 of the heap.
# memtable_total_space_in_mb: 2048

# Total space to use for commitlogs.  Since commitlog segments are
# mmapped, and hence use up address space, the default size is 32
# on 32-bit JVMs, and 1024 on 64-bit JVMs.
#
# If space gets above this value (it will round up to the next nearest
# segment multiple), Cassandra will flush every dirty CF in the oldest
# segment and remove it.  So a small total commitlog space will tend
# to cause more flush activity on less-active columnfamilies.
# commitlog_total_space_in_mb: 4096

# This sets the amount of memtable flush writer threads.  These will
# be blocked by disk io, and each one will hold a memtable in memory
# while blocked. If you have a large heap and many data directories,
# you can increase this value for better flush performance.
# By default this will be set to the amount of data directories defined.
#memtable_flush_writers: 1

# the number of full memtables to allow pending flush, that is,
# waiting for a writer thread.  At a minimum, this should be set to
# the maximum number of secondary indexes created on a single CF.
memtable_flush_queue_size: 4

# Whether to, when doing sequential writing, fsync() at intervals in
# order to force the operating system to flush the dirty
# buffers. Enable this to avoid sudden dirty buffer flushing from
# impacting read latencies. Almost always a good idea on SSDs; not
# necessarily on platters.
trickle_fsync: false
trickle_fsync_interval_in_kb: 10240

# TCP port, for commands and data
storage_port: 7000

# SSL port, for encrypted communication.  Unused unless enabled in
# encryption_options
ssl_storage_port: 7001

# Address to bind to and tell other Cassandra nodes to connect to. You
# _must_ change this if you want multiple nodes to be able to
# communicate!
# 
# Leaving it blank leaves it up to InetAddress.getLocalHost(). This
# will always do the Right Thing _if_ the node is properly configured
# (hostname, name resolution, etc), and the Right Thing is to use the
# address associated with the hostname (it might not be).
#
# Setting this to 0.0.0.0 is always wrong.
listen_address: $NODE_ADDRESS

# Address to broadcast to other Cassandra nodes
# Leaving this blank will set it to the same value as listen_address
# broadcast_address: 1.2.3.4

# Internode authentication backend, implementing IInternodeAuthenticator;
# used to allow/disallow connections from peer nodes.
# internode_authenticator: org.apache.cassandra.auth.AllowAllInternodeAuthenticator

# Whether to start the native transport server.
# Please note that the address on which the native transport is bound is the
# same as the rpc_address. The port however is different and specified below.
start_native_transport: true
# port for the CQL native transport to listen for clients on
native_transport_port: 9042
# The maximum threads for handling requests when the native transport is used.
# This is similar to rpc_max_threads though the default differs slightly (and
# there is no native_transport_min_threads, idle threads will always be stopped
# after 30 seconds).
# native_transport_max_threads: 128
#
# The maximum size of allowed frame. Frame (requests) larger than this will
# be rejected as invalid. The default is 256MB.
# native_transport_max_frame_size_in_mb: 256

# Whether to start the thrift rpc server.
start_rpc: true

# The address to bind the Thrift RPC service and native transport
# server -- clients connect here.
#
# Leaving this blank has the same effect it does for ListenAddress,
# (i.e. it will be based on the configured hostname of the node).
#
# Note that unlike ListenAddress above, it is allowed to specify 0.0.0.0
# here if you want to listen on all interfaces, but that will break clients 
# that rely on node auto-discovery.
rpc_address: localhost
# port for Thrift to listen for clients on
rpc_port: 9160

# enable or disable keepalive on rpc connections
rpc_keepalive: true

# Cassandra provides two out-of-the-box options for the RPC Server:
#
# sync  -> One thread per thrift connection. For a very large number of clients, memory
#          will be your limiting factor. On a 64 bit JVM, 180KB is the minimum stack size
#          per thread, and that will correspond to your use of virtual memory (but physical memory
#          may be limited depending on use of stack space).
#
# hsha  -> Stands for "half synchronous, half asynchronous." All thrift clients are handled
#          asynchronously using a small number of threads that does not vary with the amount
#          of thrift clients (and thus scales well to many clients). The rpc requests are still
#          synchronous (one thread per active request).
#
# The default is sync because on Windows hsha is about 30% slower.  On Linux,
# sync/hsha performance is about the same, with hsha of course using less memory.
#
# Alternatively,  can provide your own RPC server by providing the fully-qualified class name
# of an o.a.c.t.TServerFactory that can create an instance of it.
rpc_server_type: sync

# Uncomment rpc_min|max_thread to set request pool size limits.
#
# Regardless of your choice of RPC server (see above), the number of maximum requests in the
# RPC thread pool dictates how many concurrent requests are possible (but if you are using the sync
# RPC server, it also dictates the number of clients that can be connected at all).
#
# The default is unlimited and thus provides no protection against clients overwhelming the server. You are
# encouraged to set a maximum that makes sense for you in production, but do keep in mind that
# rpc_max_threads represents the maximum number of client requests this server may execute concurrently.
#
# rpc_min_threads: 16
# rpc_max_threads: 2048

# uncomment to set socket buffer sizes on rpc connections
# rpc_send_buff_size_in_bytes:
# rpc_recv_buff_size_in_bytes:

# Uncomment to set socket buffer size for internode communication
# Note that when setting this, the buffer size is limited by net.core.wmem_max
# and when not setting it it is defined by net.ipv4.tcp_wmem
# See:
# /proc/sys/net/core/wmem_max
# /proc/sys/net/core/rmem_max
# /proc/sys/net/ipv4/tcp_wmem
# /proc/sys/net/ipv4/tcp_wmem
# and: man tcp
# internode_send_buff_size_in_bytes:
# internode_recv_buff_size_in_bytes:

# Frame size for thrift (maximum message length).
thrift_framed_transport_size_in_mb: 15

# Set to true to have Cassandra create a hard link to each sstable
# flushed or streamed locally in a backups/ subdirectory of the
# keyspace data.  Removing these links is the operator's
# responsibility.
incremental_backups: false

# Whether or not to take a snapshot before each compaction.  Be
# careful using this option, since Cassandra won't clean up the
# snapshots for you.  Mostly useful if you're paranoid when there
# is a data format change.
snapshot_before_compaction: false

# Whether or not a snapshot is taken of the data before keyspace truncation
# or dropping of column families. The STRONGLY advised default of true 
# should be used to provide data safety. If you set this flag to false, you will
# lose data on truncation or drop.
auto_snapshot: true

# When executing a scan, within or across a partition, we need to keep the
# tombstones seen in memory so we can return them to the coordinator, which
# will use them to make sure other replicas also know about the deleted rows.
# With workloads that generate a lot of tombstones, this can cause performance
# problems and even exaust the server heap.
# (http://www.datastax.com/dev/blog/cassandra-anti-patterns-queues-and-queue-like-datasets)
# Adjust the thresholds here if you understand the dangers and want to
# scan more tombstones anyway.  These thresholds may also be adjusted at runtime
# using the StorageService mbean.
tombstone_warn_threshold: 1000
tombstone_failure_threshold: 100000

# Add column indexes to a row after its contents reach this size.
# Increase if your column values are large, or if you have a very large
# number of columns.  The competing causes are, Cassandra has to
# deserialize this much of the row to read a single column, so you want
# it to be small - at least if you do many partial-row reads - but all
# the index data is read for each access, so you don't want to generate
# that wastefully either.
column_index_size_in_kb: 64


# Log WARN on any batch size exceeding this value. 5kb per batch by default.
# Caution should be taken on increasing the size of this threshold as it can lead to node instability.
batch_size_warn_threshold_in_kb: 5

# Size limit for rows being compacted in memory.  Larger rows will spill
# over to disk and use a slower two-pass compaction process.  A message
# will be logged specifying the row key.
in_memory_compaction_limit_in_mb: 64

# Number of simultaneous compactions to allow, NOT including
# validation "compactions" for anti-entropy repair.  Simultaneous
# compactions can help preserve read performance in a mixed read/write
# workload, by mitigating the tendency of small sstables to accumulate
# during a single long running compactions. The default is usually
# fine and if you experience problems with compaction running too
# slowly or too fast, you should look at
# compaction_throughput_mb_per_sec first.
#
# concurrent_compactors defaults to the number of cores.
# Uncomment to make compaction mono-threaded, the pre-0.8 default.
#concurrent_compactors: 1

# Multi-threaded compaction. When enabled, each compaction will use
# up to one thread per core, plus one thread per sstable being merged.
# This is usually only useful for SSD-based hardware: otherwise, 
# your concern is usually to get compaction to do LESS i/o (see:
# compaction_throughput_mb_per_sec), not more.
multithreaded_compaction: false

# Throttles compaction to the given total throughput across the entire
# system. The faster you insert data, the faster you need to compact in
# order to keep the sstable count down, but in general, setting this to
# 16 to 32 times the rate you are inserting data is more than sufficient.
# Setting this to 0 disables throttling. Note that this account for all types
# of compaction, including validation compaction.
compaction_throughput_mb_per_sec: 16

# Track cached row keys during compaction, and re-cache their new
# positions in the compacted sstable.  Disable if you use really large
# key caches.
compaction_preheat_key_cache: true

# Throttles all outbound streaming file transfers on this node to the
# given total throughput in Mbps. This is necessary because Cassandra does
# mostly sequential IO when streaming data during bootstrap or repair, which
# can lead to saturating the network connection and degrading rpc performance.
# When unset, the default is 200 Mbps or 25 MB/s.
# stream_throughput_outbound_megabits_per_sec: 200

# How long the coordinator should wait for read operations to complete
read_request_timeout_in_ms: 5000
# How long the coordinator should wait for seq or index scans to complete
range_request_timeout_in_ms: 10000
# How long the coordinator should wait for writes to complete
write_request_timeout_in_ms: 2000
# How long a coordinator should continue to retry a CAS operation
# that contends with other proposals for the same row
cas_contention_timeout_in_ms: 1000
# How long the coordinator should wait for truncates to complete
# (This can be much longer, because unless auto_snapshot is disabled
# we need to flush first so we can snapshot before removing the data.)
truncate_request_timeout_in_ms: 60000
# The default timeout for other, miscellaneous operations
request_timeout_in_ms: 10000

# Enable operation timeout information exchange between nodes to accurately
# measure request timeouts.  If disabled, replicas will assume that requests
# were forwarded to them instantly by the coordinator, which means that
# under overload conditions we will waste that much extra time processing 
# already-timed-out requests.
#
# Warning: before enabling this property make sure to ntp is installed
# and the times are synchronized between the nodes.
cross_node_timeout: false

# Enable socket timeout for streaming operation.
# When a timeout occurs during streaming, streaming is retried from the start
# of the current file. This _can_ involve re-streaming an important amount of
# data, so you should avoid setting the value too low.
# Default value is 0, which never timeout streams.
# streaming_socket_timeout_in_ms: 0

# phi value that must be reached for a host to be marked down.
# most users should never need to adjust this.
# phi_convict_threshold: 8

# endpoint_snitch -- Set this to a class that implements
# IEndpointSnitch.  The snitch has two functions:
# - it teaches Cassandra enough about your network topology to route
#   requests efficiently
# - it allows Cassandra to spread replicas around your cluster to avoid
#   correlated failures. It does this by grouping machines into
#   "datacenters" and "racks."  Cassandra will do its best not to have
#   more than one replica on the same "rack" (which may not actually
#   be a physical location)
#
# IF YOU CHANGE THE SNITCH AFTER DATA IS INSERTED INTO THE CLUSTER,
# YOU MUST RUN A FULL REPAIR, SINCE THE SNITCH AFFECTS WHERE REPLICAS
# ARE PLACED.
#
# Out of the box, Cassandra provides
#  - SimpleSnitch:
#    Treats Strategy order as proximity. This can improve cache
#    locality when disabling read repair.  Only appropriate for
#    single-datacenter deployments.
#  - GossipingPropertyFileSnitch
#    This should be your go-to snitch for production use.  The rack
#    and datacenter for the local node are defined in
#    cassandra-rackdc.properties and propagated to other nodes via
#    gossip.  If cassandra-topology.properties exists, it is used as a
#    fallback, allowing migration from the PropertyFileSnitch.
#  - PropertyFileSnitch:
#    Proximity is determined by rack and data center, which are
#    explicitly configured in cassandra-topology.properties.
#  - Ec2Snitch:
#    Appropriate for EC2 deployments in a single Region. Loads Region
#    and Availability Zone information from the EC2 API. The Region is
#    treated as the datacenter, and the Availability Zone as the rack.
#    Only private IPs are used, so this will not work across multiple
#    Regions.
#  - Ec2MultiRegionSnitch:
#    Uses public IPs as broadcast_address to allow cross-region
#    connectivity.  (Thus, you should set seed addresses to the public
#    IP as well.) You will need to open the storage_port or
#    ssl_storage_port on the public IP firewall.  (For intra-Region
#    traffic, Cassandra will switch to the private IP after
#    establishing a connection.)
#  - RackInferringSnitch:
#    Proximity is determined by rack and data center, which are
#    assumed to correspond to the 3rd and 2nd octet of each node's IP
#    address, respectively.  Unless this happens to match your
#    deployment conventions, this is best used as an example of
#    writing a custom Snitch class and is provided in that spirit.
#
# You can use a custom Snitch by setting this to the full class name
# of the snitch, which will be assumed to be on your classpath.
endpoint_snitch: SimpleSnitch

# controls how often to perform the more expensive part of host score
# calculation
dynamic_snitch_update_interval_in_ms: 100 
# controls how often to reset all host scores, allowing a bad host to
# possibly recover
dynamic_snitch_reset_interval_in_ms: 600000
# if set greater than zero and read_repair_chance is < 1.0, this will allow
# 'pinning' of replicas to hosts in order to increase cache capacity.
# The badness threshold will control how much worse the pinned host has to be
# before the dynamic snitch will prefer other replicas over it.  This is
# expressed as a double which represents a percentage.  Thus, a value of
# 0.2 means Cassandra would continue to prefer the static snitch values
# until the pinned host was 20% worse than the fastest.
dynamic_snitch_badness_threshold: 0.1

# request_scheduler -- Set this to a class that implements
# RequestScheduler, which will schedule incoming client requests
# according to the specific policy. This is useful for multi-tenancy
# with a single Cassandra cluster.
# NOTE: This is specifically for requests from the client and does
# not affect inter node communication.
# org.apache.cassandra.scheduler.NoScheduler - No scheduling takes place
# org.apache.cassandra.scheduler.RoundRobinScheduler - Round robin of
# client requests to a node with a separate queue for each
# request_scheduler_id. The scheduler is further customized by
# request_scheduler_options as described below.
request_scheduler: org.apache.cassandra.scheduler.NoScheduler

# Scheduler Options vary based on the type of scheduler
# NoScheduler - Has no options
# RoundRobin
#  - throttle_limit -- The throttle_limit is the number of in-flight
#                      requests per client.  Requests beyond 
#                      that limit are queued up until
#                      running requests can complete.
#                      The value of 80 here is twice the number of
#                      concurrent_reads + concurrent_writes.
#  - default_weight -- default_weight is optional and allows for
#                      overriding the default which is 1.
#  - weights -- Weights are optional and will default to 1 or the
#               overridden default_weight. The weight translates into how
#               many requests are handled during each turn of the
#               RoundRobin, based on the scheduler id.
#
# request_scheduler_options:
#    throttle_limit: 80
#    default_weight: 5
#    weights:
#      Keyspace1: 1
#      Keyspace2: 5

# request_scheduler_id -- An identifier based on which to perform
# the request scheduling. Currently the only valid option is keyspace.
# request_scheduler_id: keyspace

# Enable or disable inter-node encryption
# Default settings are TLS v1, RSA 1024-bit keys (it is imperative that
# users generate their own keys) TLS_RSA_WITH_AES_128_CBC_SHA as the cipher
# suite for authentication, key exchange and encryption of the actual data transfers.
# Use the DHE/ECDHE ciphers if running in FIPS 140 compliant mode.
# NOTE: No custom encryption options are enabled at the moment
# The available internode options are : all, none, dc, rack
#
# If set to dc cassandra will encrypt the traffic between the DCs
# If set to rack cassandra will encrypt the traffic between the racks
#
# The passwords used in these options must match the passwords used when generating
# the keystore and truststore.  For instructions on generating these files, see:
# http://download.oracle.com/javase/6/docs/technotes/guides/security/jsse/JSSERefGuide.html#CreateKeystore
#
server_encryption_options:
    internode_encryption: none
    keystore: conf/.keystore
    keystore_password: cassandra
    truststore: conf/.truststore
    truststore_password: cassandra
    # More advanced defaults below:
    # protocol: TLS
    # algorithm: SunX509
    # store_type: JKS
    # cipher_suites: [TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA]
    # require_client_auth: false

# enable or disable client/server encryption.
client_encryption_options:
    enabled: false
    keystore: conf/.keystore
    keystore_password: cassandra
    # require_client_auth: false
    # Set trustore and truststore_password if require_client_auth is true
    # truststore: conf/.truststore
    # truststore_password: cassandra
    # More advanced defaults below:
    # protocol: TLS
    # algorithm: SunX509
    # store_type: JKS
    # cipher_suites: [TLS_RSA_WITH_AES_128_CBC_SHA,TLS_RSA_WITH_AES_256_CBC_SHA,TLS_DHE_RSA_WITH_AES_128_CBC_SHA,TLS_DHE_RSA_WITH_AES_256_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA]

# internode_compression controls whether traffic between nodes is
# compressed.
# can be:  all  - all traffic is compressed
#          dc   - traffic between different datacenters is compressed
#          none - nothing is compressed.
internode_compression: all

# Enable or disable tcp_nodelay for inter-dc communication.
# Disabling it will result in larger (but fewer) network packets being sent,
# reducing overhead from the TCP protocol itself, at the cost of increasing
# latency if you block for cross-datacenter responses.
inter_dc_tcp_nodelay: false

# Enable or disable kernel page cache preheating from contents of the key cache after compaction.
# When enabled it would preheat only first "page" (4KB) of each row to optimize
# for sequential access. Note: This could be harmful for fat rows, see CASSANDRA-4937
# for further details on that topic.
preheat_kernel_page_cache: false

EOF


# Start up Cassandra
echo "## Starting Apache Cassandra"
sudo $CASSANDRA_HOME/bin/cassandra
