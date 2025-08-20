local storage = require("mdpaste.storage")
local formatter = require("mdpaste.formatter")

local M = {}

local ClipboardType = { TEXT = "text", IMAGE = "image", FILE = "file" }

function M.get_clipboard_text()
	local handle = io.popen("pbpaste 2>/dev/null")
	if not handle then
		return nil, "Failed to execute pbpaste"
	end

	local result = handle:read("*all")
	local success = handle:close()

	if not success then
		return nil, "pbpaste command failed"
	end

	-- Remove trailing newline if present
	if result and result:sub(-1) == "\n" then
		result = result:sub(1, -2)
	end

	return result, nil
end

function M.has_clipboard_image()
	-- Use pngpaste to check if image is available
	local handle = io.popen("pngpaste - 2>/dev/null >/dev/null")
	if not handle then
		return false
	end

	local success = handle:close()
	return success == true
end

function M.get_clipboard_files()
	local script = [[
    use AppleScript version "2.4"
    use framework "Foundation"
    use scripting additions
    
    set pb to current application's NSPasteboard's generalPasteboard()
    set urls to pb's readObjectsForClasses_options_({current application's NSURL}, missing value)
    set xs to {}
    repeat with u in urls
        set p to (u's |path|) as text
        set end of xs to p
    end repeat
    set AppleScript's text item delimiters to linefeed
    return xs as text
  ]]

	local handle = io.popen("osascript -e " .. vim.fn.shellescape(script) .. " 2>/dev/null")
	if not handle then
		return nil, "Failed to execute osascript"
	end

	local result = handle:read("*all")
	local success = handle:close()

	if not success then
		return nil, "osascript command failed"
	end

	if not result or result == "" then
		return {}, nil
	end

	-- Remove trailing newline and split by newline
	result = result:gsub("\n$", "")
	local files = {}
	for path in result:gmatch("[^\n]+") do
		if path and path ~= "" then
			table.insert(files, path)
		end
	end

	return files, nil
end

function M.detect_clipboard_type()
	-- 1. Check for files first
	local files, err = M.get_clipboard_files()
	if not err and files and #files > 0 then
		return ClipboardType.FILE, files
	end

	-- 2. Check for image
	if M.has_clipboard_image() then
		return ClipboardType.IMAGE, nil
	end

	-- 3. Default to text
	return ClipboardType.TEXT, nil
end

function M.process_text()
	local text, err = M.get_clipboard_text()
	if err then
		return nil, err
	end

	return formatter.format_text(text), nil
end

function M.process_image(config)
	local relative_path = storage.generate_image_filename(config)
	local full_path = storage.get_full_path(config.base_path, relative_path)

	-- Ensure directory exists
	local dir = vim.fn.fnamemodify(full_path, ":h")
	local ok, err = storage.ensure_dir(dir)
	if not ok then
		return nil, err
	end

	-- Save image using pngpaste
	local cmd = "pngpaste " .. vim.fn.shellescape(full_path) .. " 2>/dev/null"
	local handle = io.popen(cmd)
	if not handle then
		return nil, "Failed to execute pngpaste"
	end

	local success = handle:close()
	if not success then
		return nil, "Failed to save image with pngpaste"
	end

	-- Generate relative path for markdown
	local current_file = vim.fn.expand("%:p")
	local rel_path = storage.get_relative_path(current_file, full_path)
	return formatter.format_image(rel_path), nil
end

function M.process_files(config, file_paths)
	local saved_paths = {}

	for _, src_path in ipairs(file_paths) do
		if not storage.file_exists(src_path) then
			return nil, "Source file does not exist: " .. src_path
		end

		local filename = vim.fn.fnamemodify(src_path, ":t")
		local relative_path = storage.generate_file_filename(config, filename)
		local dst_path = storage.get_full_path(config.base_path, relative_path)

		-- Ensure directory exists
		local dir = vim.fn.fnamemodify(dst_path, ":h")
		local ok, err = storage.ensure_dir(dir)
		if not ok then
			return nil, err
		end

		-- Copy file
		local copy_ok, copy_err = storage.copy_file(src_path, dst_path)
		if not copy_ok then
			return nil, copy_err
		end

		-- Generate relative path for markdown
		local current_file = vim.fn.expand("%:p")
		local rel_path = storage.get_relative_path(current_file, dst_path)
		table.insert(saved_paths, rel_path)
	end

	return formatter.format_files(saved_paths), nil
end

function M.process_clipboard(config)
	local clipboard_type, data = M.detect_clipboard_type()

	if clipboard_type == ClipboardType.TEXT then
		return M.process_text()
	elseif clipboard_type == ClipboardType.IMAGE then
		return M.process_image(config)
	elseif clipboard_type == ClipboardType.FILE then
		return M.process_files(config, data)
	else
		return nil, "Unknown clipboard type"
	end
end

return M
