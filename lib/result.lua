local ResultMT = {}
ResultMT.__index = ResultMT

function ResultMT:assert(msg)
    if not self.success then
        local err = msg or "Action failed"
        if self.reason then
            err = err .. " (" .. self.reason .. ")"
        end
        if BInt._active_context then
            BInt._active_context:_fail(err)
        else
            error("[Integration] " .. err)
        end
    end
    return self
end

function ResultMT:assert_fail(msg)
    if self.success then
        local err = msg or "Expected action to fail, but it succeeded"
        if BInt._active_context then
            BInt._active_context:_fail(err)
        else
            error("[Integration] " .. err)
        end
    end
    return self
end

function BInt.Result(success, data)
    local r = data or {}
    r.success = success
    return setmetatable(r, ResultMT)
end

function BInt.Ok(data)
    return BInt.Result(true, data)
end

function BInt.Fail(reason, data)
    local r = data or {}
    r.reason = reason
    return BInt.Result(false, r)
end
