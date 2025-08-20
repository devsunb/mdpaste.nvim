local M = {}

function M.ensure_dir(path)
	local ok = pcall(vim.fn.mkdir, path, "p")
	if not ok then
		return false, "Failed to create directory: " .. path
	end
	return true, nil
end

function M.generate_path_prefix(config)
	if type(config.path_prefix) == "function" then
		return config.path_prefix()
	else
		return config.path_prefix or ""
	end
end

function M.generate_image_filename(config)
	local path_prefix = M.generate_path_prefix(config)
	local dir_path = M.get_full_path(config.base_path, path_prefix)
	local base_filename = config.filename_generator("image", nil, dir_path)
	local filename = base_filename .. "." .. config.image_format
	if path_prefix == "" then
		return filename
	else
		return path_prefix .. "/" .. filename
	end
end

function M.generate_file_filename(config, original_name)
	local path_prefix = M.generate_path_prefix(config)
	local dir_path = M.get_full_path(config.base_path, path_prefix)
	local filename = config.filename_generator("file", original_name, dir_path)

	if path_prefix == "" then
		return filename
	else
		return path_prefix .. "/" .. filename
	end
end

function M.get_full_path(base_path, relative_path)
	return vim.fs.normalize(base_path .. "/" .. relative_path)
end

function M.get_relative_path(from, to)
	local min_len = math.min(to:len(), from:len())
	local mismatch = 0

	for i = 1, min_len do
		if to:sub(i, i) ~= from:sub(i, i) then
			mismatch = i
			break
		end
	end

	local to_diff = to:sub(mismatch)
	local from_diff = from:sub(mismatch)

	local rel_path = ""
	for _ in from_diff:gmatch("/") do
		rel_path = rel_path .. "../"
	end

	return rel_path .. to_diff
end

function M.copy_file(src, dst)
	local src_file = io.open(src, "rb")
	if not src_file then
		return false, "Failed to open source file: " .. src
	end

	local content = src_file:read("*all")
	src_file:close()

	if not content then
		return false, "Failed to read source file: " .. src
	end

	local dst_file = io.open(dst, "wb")
	if not dst_file then
		return false, "Failed to create destination file: " .. dst
	end

	local ok, err = dst_file:write(content)
	dst_file:close()

	if not ok then
		return false, "Failed to write to destination file: " .. dst .. " - " .. (err or "unknown error")
	end

	return true, nil
end

function M.file_exists(path)
	local stat = vim.loop.fs_stat(path)
	return stat ~= nil
end

return M
