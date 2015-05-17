noflo = require 'noflo'
osc = require 'osc-min'
dgram = require 'dgram'

sendOsc = (socket, data) ->
    buf = osc.toBuffer({
      address: "/synchrony/change",
      args: [ data.north, data.west, data.south, data.east ]
    });
    outport = 57120
    socket.send buf, 0, buf.length, outport, "localhost"

exports.getComponent = () ->
  c = new noflo.Component
  c.description = 'Send sensor data over OSC'

  c.data =
    north: 0
    west: 0
    south: 0
    east: 0

  c.socket = dgram.createSocket 'udp4'

  c.outPorts.add 'out',
    datatype: 'object'

  c.inPorts.add 'north',
    process: (event, payload) ->
      return unless event is 'data'
      c.data.north = payload
      sendOsc c.socket, c.data
      c.outPorts.out.send c.data
  c.inPorts.add 'west',
    datatype: 'object'
    process: (event, payload) ->
      return unless event is 'data'
      c.data.west = payload
      sendOsc c.socket, c.data
      c.outPorts.out.send c.data
  c.inPorts.add 'south',
    process: (event, payload) ->
      return unless event is 'data'
      c.data.south = payload
      sendOsc c.socket, c.data
      c.outPorts.out.send c.data
  c.inPorts.add 'east',
    process: (event, payload) ->
      return unless event is 'data'
      c.data.east = payload
      sendOsc c.socket, c.data
      c.outPorts.out.send c.data

  return c
