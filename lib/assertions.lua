function BInt._assertion_methods:_fail(msg)
	self._failed = true
	self._fail_message = msg
	coroutine.yield("FAIL", msg)
end

function BInt._assertion_methods:_log(msg)
	BInt._output.log(self._name, tostring(msg))
end
