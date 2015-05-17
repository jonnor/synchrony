s.boot;

// -- synths
SynthDef(\sine, { |freq=400, amp=0.5 |
    Out.ar(0, SinOsc.ar(freq, 0, amp))
}).add;

a = Synth(\sine);

// -- Put code to change the sound here -- !
var onChange = { |north=0, west=0, south=0, east=0|
    // Each value is in range 1-200 centimeter
    // 0 means out-of-range
    var closeness;
    "N:%, E:%, S:%, W:%\n".postf(north, east, south, west);

    // Simulate a Haravot dance
    // where people are in a circle, the closer the more intense. If one person does is not in circle: no sound!!
    north = (200-north)/200;
    west = (200-west)/200;
    south = (200-south)/200;
    east = (200-east)/200;
    closeness = north*west*south*east;
    a.set("amp", closeness*2);
};


// Standard code here. No need to change things here!
// Simulator
var win = Window.new("Simulator", Rect(200,200,200,200));
var north = Slider.new(win,Rect(0,30,30,170)).resize_(1);
var west = Slider.new(win,Rect(30,30,30,170)).resize_(1);
var south = Slider.new(win,Rect(60,30,30,170)).resize_(1);
var east = Slider.new(win,Rect(90,30,30,170)).resize_(1);
var onSliderChange = {
    var spec = ControlSpec.new(0, 200);
    onChange.value(spec.map(north.value), spec.map(west.value),
        spec.map(south.value), spec.map(east.value));
};
north.action = onSliderChange;
west.action = onSliderChange;
south.action = onSliderChange;
east.action = onSliderChange;
win.front;

// Real-deal
OSCFunc.new({ |msg, time, addr, recvPort|
    "OSRC received: ".post; msg.postln;
    // onChange.value
}, "/synchrony/change");

// Self-test OSC
// NetAddr.localAddr.sendMsg("/synchrony/change", "soo");
