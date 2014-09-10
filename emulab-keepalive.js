var spawn = require('child_process'),
    sys = require('sys');

function puts(error, stdout, stderr) {
    sys.puts(stdout);
}

(function loop() {
    console.log(new Date());
//    spawn.spawn('ssh', ['-t', 'yossupp@node-0.cassandra-morphous.ISS.emulab.net', '"echo `date` >> /tmp/heartbeat"']);
    //spawn.exec('ssh -t -t -t yossupp@node-0.cassandra-morphous.ISS.emulab.net "ps aux | grep cassandra; echo `date` >> /tmp/heartbeat";, puts);
    //spawn.exec('ssh -t -t -t yossupp@node-1.cassandra-morphous.ISS.emulab.net "sudo apt-get update"', puts);
    spawn.exec('ssh -t -t -t yossupp@loadgen-0.cassandra-morphous.ISS.emulab.net "java -jar morphous-script-1.0-SNAPSHOT.one-jar.jar"', puts);
    setTimeout(loop, 10 * 60 * 1000);
})();



