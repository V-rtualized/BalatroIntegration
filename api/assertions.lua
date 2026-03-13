function BInt._assertion_methods:fail(msg)
	self:_fail(msg)
end

function BInt._assertion_methods:log(msg)
	self:_log(msg)
end

function BInt._assertion_methods:assert_eq(a, b, msg)
	if a ~= b then
		self:_fail((msg or "assert_eq") .. ": expected " .. tostring(b) .. ", got " .. tostring(a))
	end
end

function BInt._assertion_methods:assert_neq(a, b, msg)
	if a == b then
		self:_fail((msg or "assert_neq") .. ": expected values to differ, both are " .. tostring(a))
	end
end

function BInt._assertion_methods:assert_gt(a, b, msg)
	if not (a > b) then
		self:_fail((msg or "assert_gt") .. ": expected " .. tostring(a) .. " > " .. tostring(b))
	end
end

function BInt._assertion_methods:assert_gte(a, b, msg)
	if not (a >= b) then
		self:_fail((msg or "assert_gte") .. ": expected " .. tostring(a) .. " >= " .. tostring(b))
	end
end

function BInt._assertion_methods:assert_lt(a, b, msg)
	if not (a < b) then
		self:_fail((msg or "assert_lt") .. ": expected " .. tostring(a) .. " < " .. tostring(b))
	end
end

function BInt._assertion_methods:assert_lte(a, b, msg)
	if not (a <= b) then
		self:_fail((msg or "assert_lte") .. ": expected " .. tostring(a) .. " <= " .. tostring(b))
	end
end

function BInt._assertion_methods:assert_true(v, msg)
	if not v then
		self:_fail((msg or "assert_true") .. ": expected truthy, got " .. tostring(v))
	end
end

function BInt._assertion_methods:assert_false(v, msg)
	if v then
		self:_fail((msg or "assert_false") .. ": expected falsy, got " .. tostring(v))
	end
end

function BInt._assertion_methods:assert_contains(tbl, v, msg)
	for _, item in ipairs(tbl) do
		if item == v then
			return
		end
	end
	self:_fail((msg or "assert_contains") .. ": table does not contain " .. tostring(v))
end
