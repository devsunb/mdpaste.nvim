local M = {}

local image_extensions = { ".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg", ".tiff", ".tif" }

local video_extensions = { ".mp4", ".avi", ".mov", ".mkv", ".webm", ".flv", ".wmv", ".m4v" }

local pdf_extensions = { ".pdf" }

function M.get_file_extension(filename)
	return string.match(filename, "%.([^%.]+)$") or ""
end

function M.is_image_file(filename)
	local ext = "." .. M.get_file_extension(filename):lower()
	for _, image_ext in ipairs(image_extensions) do
		if ext == image_ext then
			return true
		end
	end
	return false
end

function M.is_video_file(filename)
	local ext = "." .. M.get_file_extension(filename):lower()
	for _, video_ext in ipairs(video_extensions) do
		if ext == video_ext then
			return true
		end
	end
	return false
end

function M.is_pdf_file(filename)
	local ext = "." .. M.get_file_extension(filename):lower()
	for _, pdf_ext in ipairs(pdf_extensions) do
		if ext == pdf_ext then
			return true
		end
	end
	return false
end

function M.is_embeddable_file(filename)
	return M.is_image_file(filename) or M.is_video_file(filename) or M.is_pdf_file(filename)
end

function M.format_text(text)
	return text
end

function M.format_image(image_path)
	return "![[" .. image_path .. "]]"
end

function M.format_file(file_path)
	local filename = vim.fn.fnamemodify(file_path, ":t")

	if M.is_embeddable_file(filename) then
		return "![[" .. file_path .. "]]"
	else
		return "[" .. filename .. "](" .. file_path .. ")"
	end
end

function M.format_files(file_paths)
	local results = {}

	for _, file_path in ipairs(file_paths) do
		table.insert(results, M.format_file(file_path))
	end

	return table.concat(results, "\n")
end

return M
