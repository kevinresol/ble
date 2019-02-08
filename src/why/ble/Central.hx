package why.ble;

import tink.state.*;

using tink.CoreApi;

@:forward
abstract Central(CentralObject) from CentralObject to CentralObject {
	public inline function find(filter:Peripheral->Bool):Future<Peripheral> {
		return this.advertisements.nextTime(filter);
	}
}

class CentralBase implements CentralObject {
	
	public var status(default, null):Observable<Status>;
	public var peripherals(default, null):Peripherals;
	public var advertisements(default, null):Signal<Peripheral>;
	
	var statusState:State<Status>;
	
	function new() {
		
		status = statusState = new State<Status>(Unknown);
		peripherals = new Peripherals();
		
		advertisements = Signal.generate(function(trigger) {
			var bindings:CallbackLink = null;
			peripherals.observableValues.bind(null, function(list) {
				bindings.dissolve();
				bindings = [for(peripheral in list) peripheral.advertisement.bind(null, function(_) trigger(peripheral))];
			});
		});
	}
	
	public function startScan():Void throw 'abstract';
	public function stopScan():Void throw 'abstract';
}

interface CentralObject {
	var status(default, null):Observable<Status>;
	var peripherals(default, null):Peripherals;
	var advertisements(default, null):Signal<Peripheral>;
	function startScan():Void;
	function stopScan():Void;
}

class Peripherals extends ObservableMap<String, Peripheral> {
	public var discovered(default, null):Signal<Peripheral>;
	public var gone(default, null):Signal<Peripheral>;
	
	var discoveredTrigger:SignalTrigger<Peripheral>;
	var goneTrigger:SignalTrigger<Peripheral>;
	
	public function new() {
		super(new Map());
		discovered = discoveredTrigger = Signal.trigger();
		gone = goneTrigger = Signal.trigger();
	}
	
	override function set(k, v) {
		var existed = map.exists(k);
		super.set(k, v);
		if(!existed) discoveredTrigger.trigger(v);
	}
	
	override function remove(k) {
		var existed = map.exists(k);
		var value = map.get(k);
		var ret = super.remove(k);
		if(existed) goneTrigger.trigger(value);
		return ret;
	}
}


enum Status {
	Unknown;
	Unsupported;
	Unauthorized;
	Resetting;
	On;
	Off;
}