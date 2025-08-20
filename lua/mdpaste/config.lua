local M = {}

M.defaults = {
	base_path = vim.fn.expand("~/Documents/mdpaste"),
	image_format = "png",
	path_prefix = function()
		return os.date("%Y/%m")
	end,
	filename_generator = function(file_type, original_name, dir_path)
		if file_type == "image" then
			return os.date("%Y-%m-%d-%H%M%S")
		else
			return original_name or os.date("%Y-%m-%d-%H%M%S")
		end
	end,
	debug = false,
}

M.options = {}

function M.setup(user_config)
	M.options = vim.tbl_deep_extend("force", M.defaults, user_config or {})
	M.options.base_path = vim.fn.expand(M.options.base_path)
	return M.options
end

function M.get()
	return M.options
end

return M
