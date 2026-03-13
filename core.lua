BInt = {
	_MOD_METADATA = SMODS.current_mod,
	_tests = {},
	_events = {},
	_active_coroutine = nil,
	_active_context = nil,
	_wait_condition = nil,
	_running = false,
	_test_queue = {},
	_suite_results = nil,
	_assertion_methods = {},
}

function BInt._load(file)
	local chunk, err = SMODS.load_file(file, BInt._MOD_METADATA.id)
	if chunk then
		local ok, result = pcall(chunk)
		if not ok then
			sendWarnMessage("Failed to process: " .. tostring(result), BInt._MOD_METADATA.id)
		end
		return result
	else
		sendWarnMessage("Failed to load: " .. tostring(err), BInt._MOD_METADATA.id)
	end
end

function BInt._load_dir(directory, recursive)
	local dir_path = BInt._MOD_METADATA.path .. "/" .. directory
	local items = NFS.getDirectoryItemsInfo(dir_path)

	for _, item in ipairs(items) do
		local path = directory .. "/" .. item.name
		if item.type ~= "directory" then
			BInt._load(path)
		elseif recursive then
			BInt._load_dir(path, recursive)
		end
	end
end

BInt._dp_api = nil
if next(SMODS.find_mod("DebugPlus")) then
	local ok, dp_api = pcall(require, "debugplus.api")
	if ok and dp_api and dp_api.isVersionCompatible(1) then
		BInt._dp_api = dp_api.registerID(BInt._MOD_METADATA.id)
	end
end

BInt._load_dir("lib")
BInt._load_dir("api")
BInt._load_dir("tests")
