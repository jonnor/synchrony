osc = require 'osc-min'
dgram = require 'dgram'

buf = osc.toBuffer({
  address: "/synchrony/change",
  args: [ "hello from node.js" ]
});
outport = 57120
udp = dgram.createSocket 'udp4'
udp.send buf, 0, buf.length, outport, "localhost"
