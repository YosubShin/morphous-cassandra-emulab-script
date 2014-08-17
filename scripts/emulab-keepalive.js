var spawn = require('child_process');

(function loop() {
    console.log(new Date());
    spawn.spawn('ssh', ['yossupp@node-0.cassandra-morphous.ISS.emulab.net', 'echo `date` >> /tmp/heartbeat']);
    setTimeout(loop, 60 * 1000);
})();



