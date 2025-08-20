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

function M.get_relative_path(base_path, full_path)
	-- Get current file path
	local current_file = vim.fn.expand("%:p")
	local current_dir = vim.fn.fnamemodify(current_file, ":h")

	-- Calculate relative path from current file's directory to the target file
	local full_normalized = vim.fs.normalize(full_path)
	local current_dir_normalized = vim.fs.normalize(current_dir)

	-- Use vim's fnamemodify to get relative path from current directory
	local rel_path = vim.fn.fnamemodify(full_normalized, ":~:.")

	-- If we're not in the right directory context, manually calculate
	if vim.fn.getcwd() ~= current_dir_normalized then
		-- Change to current file's directory temporarily to get proper relative path
		local old_cwd = vim.fn.getcwd()
		vim.cmd("cd " .. vim.fn.fnameescape(current_dir_normalized))
		rel_path = vim.fn.fnamemodify(full_normalized, ":.")
		vim.cmd("cd " .. vim.fn.fnameescape(old_cwd))
	end

	-- Ensure it starts with ./
	if not vim.startswith(rel_path, "./") and not vim.startswith(rel_path, "../") then
		rel_path = "./" .. rel_path
	end

	return rel_path
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
