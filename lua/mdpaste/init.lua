local config = require("mdpaste.config")
local clipboard = require("mdpaste.clipboard")

local M = {}

function M.setup(user_config)
	config.setup(user_config)
end

function M.paste()
	local opts = config.get()

	if opts.debug then
		print("mdpaste.nvim: Processing clipboard...")
	end

	-- Process clipboard content
	local result, err = clipboard.process_clipboard(opts)

	if err then
		vim.notify("mdpaste.nvim: " .. err, vim.log.levels.ERROR)
		return
	end

	if not result or result == "" then
		if opts.debug then
			print("mdpaste.nvim: No content to paste")
		end
		return
	end

	-- Insert the result at cursor position
	M.insert_text(result)

	if opts.debug then
		print("mdpaste.nvim: Content pasted successfully")
	end
end

function M.insert_text(text)
	local lines = vim.split(text, "\n", { plain = true })

	-- Get current cursor position
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1 -- 0-indexed
	local col = cursor[2]

	if #lines == 1 then
		-- Single line: insert at cursor position
		local current_line = vim.api.nvim_get_current_line()
		local new_line = current_line:sub(1, col) .. text .. current_line:sub(col + 1)
		vim.api.nvim_set_current_line(new_line)

		-- Move cursor to end of inserted text
		vim.api.nvim_win_set_cursor(0, { row + 1, col + #text })
	else
		-- Multiple lines
		local current_line = vim.api.nvim_get_current_line()
		local before = current_line:sub(1, col)
		local after = current_line:sub(col + 1)

		-- Prepare new lines
		local new_lines = {}
		for i, line in ipairs(lines) do
			if i == 1 then
				table.insert(new_lines, before .. line)
			elseif i == #lines then
				table.insert(new_lines, line .. after)
			else
				table.insert(new_lines, line)
			end
		end

		-- Replace current line and insert additional lines
		vim.api.nvim_buf_set_lines(0, row, row + 1, false, new_lines)

		-- Move cursor to end of last inserted line
		local last_line = new_lines[#new_lines]
		vim.api.nvim_win_set_cursor(0, { row + #new_lines, #last_line - #after })
	end
end

return M
