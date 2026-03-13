BInt._output = {}

local _dp_logger = BInt._dp_api and BInt._dp_api.logger or nil

local function log_info(msg)
	if _dp_logger then
		pcall(_dp_logger.info, msg)
	else
		sendDebugMessage(msg, BInt._MOD_METADATA.id)
	end
end

local function log_warn(msg)
	if _dp_logger then
		pcall(_dp_logger.warn, msg)
	else
		sendDebugMessage(msg, BInt._MOD_METADATA.id)
	end
end

function BInt._output.log(test_name, msg)
	log_info("[" .. test_name .. "] " .. msg)
end

function BInt._output.suite_start(count)
	log_info("Running " .. count .. " tests...")
end

function BInt._output.test_start(name)
	log_info("START " .. name)
end

function BInt._output.test_pass(name, duration)
	log_info("PASS  " .. name .. " (" .. string.format("%.1f", duration) .. "s)")
end

function BInt._output.test_fail(name, message, duration)
	log_warn("FAIL  " .. name .. " (" .. string.format("%.1f", duration) .. "s)")
	log_warn("  └─ " .. message)
end

function BInt._output.suite_complete(results)
	local msg = "Results: "
		.. results.passed
		.. " passed, "
		.. results.failed
		.. " failed ("
		.. string.format("%.1f", results.duration)
		.. "s total)"
	if results.failed == 0 then
		log_info(msg)
	else
		log_warn(msg)
	end
	BInt._output.write_file(results)
end

function BInt._output.write_file(results)
	local path = BInt._MOD_METADATA.path .. "results/"
	NFS.createDirectory(path)
	local file = NFS.newFile(path .. "latest.txt")
	file:open("w")

	file:write("Integration Test Results\n")
	file:write("========================\n\n")
	file:write("Total: " .. results.total .. "\n")
	file:write("Passed: " .. results.passed .. "\n")
	file:write("Failed: " .. results.failed .. "\n")
	file:write("Duration: " .. string.format("%.1f", results.duration) .. "s\n\n")

	if #results.errors > 0 then
		file:write("Failures:\n")
		for _, err in ipairs(results.errors) do
			file:write("  FAIL  " .. err.name .. "\n")
			file:write("    └─ " .. err.message .. "\n")
		end
	end

	file:close()
end
