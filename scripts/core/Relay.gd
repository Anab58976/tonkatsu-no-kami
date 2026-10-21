class_name Relay
extends Node
## Tiny helper to await "whichever happens first" safely. Because the relay is
## a child of the waiting node, freeing that node also frees the relay and the
## waiting coroutine is simply dropped (never resumed on a dead instance).

signal done


func fire(_a = null, _b = null) -> void:
	done.emit()


## Waits for the first of `signals` or `timeout` seconds (<=0: no timeout).
static func first(owner: Node, signals: Array, timeout := 0.0) -> Relay:
	var r := Relay.new()
	owner.add_child(r)
	for s in signals:
		(s as Signal).connect(r.fire, CONNECT_ONE_SHOT)
	if timeout > 0.0:
		var t := Timer.new()
		t.one_shot = true
		t.wait_time = timeout
		r.add_child(t)
		t.timeout.connect(r.fire)
		t.start()
	r.done.connect(r.queue_free, CONNECT_DEFERRED)
	return r
