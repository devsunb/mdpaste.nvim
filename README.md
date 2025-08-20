# mdpaste.nvim

A Neovim plugin that intelligently pastes clipboard content as markdown, handling text, images, and files with automatic formatting.

> [!WARNING]
> This plugin is in development and is not yet available.

## Limitations

Currently, this plugin only supports macOS.

## Features

- **Text**: Paste clipboard text as-is
- **Images**: Save clipboard images and insert as markdown embeds (`![[./path/to/image.png]]`)
- **Files**: Copy clipboard files and insert as markdown links or embeds based on file type
- **Multi-file support**: Handle multiple files at once
- **Configurable**: Customize base path, keymaps, and more
- **Pure Lua**: No external dependencies beyond system tools

## Requirements

- macOS (uses `pbpaste`, `pngpaste`, `osascript`)
- [pngpaste](https://github.com/jcsalterego/pngpaste): `brew install pngpaste`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'devsunb/mdpaste.nvim',
  ft = 'markdown',
  cmd = { 'MDPaste' },
  opts = { base_path = '~/Documents/mdpaste' },
}
```

## Configuration

```lua
require('mdpaste').setup({
  -- File storage base path
  base_path = vim.fn.expand("~/Documents/mdpaste"),

  -- Path prefix configuration
  -- function: custom prefix generator
  -- string: static prefix
  path_prefix = function()
    return os.date("%Y/%m")
  end,

  -- Filename generator function
  -- file_type: "image" or "file"
  -- original_name: original filename (for files only)
  -- dir_path: target directory path
  filename_generator = function(file_type, original_name, dir_path)
    if file_type == "image" then
      return os.date("%Y-%m-%d-%H%M%S")
    else
      return original_name or os.date("%Y-%m-%d-%H%M%S")
    end
  end,

  -- Image format for saved images
  image_format = "png",

  -- Enable debug messages
  debug = false,
})
```

## Usage

### Commands

- `:MDPaste` - Process clipboard and insert formatted content at cursor

### Manual Keymaps

If you prefer to set up keymaps manually:

```lua
-- Normal mode
vim.keymap.set('n', '<Leader>p', ':MDPaste<CR>', { desc = 'MDPaste' })

-- Insert mode
vim.keymap.set('i', '<C-p>', '<Esc>:MDPaste<CR>a', { desc = 'MDPaste' })
```

### File Organization

By default, files are organized in a date-based structure (YYYY/MM/):

```
~/Documents/mdpaste/
├── 2025/
│   ├── 08/
│   │   ├── 2025-08-19-143052.png
│   │   ├── document.pdf
│   │   └── screenshot.jpg
│   └── 09/
│       └── video.mp4
```

#### Custom Path Prefix Examples

```lua
-- Static prefix
path_prefix = "images"
-- Results in: ~/Documents/mdpaste/images/filename.png

-- No prefix (files in root)
path_prefix = function() return "" end
-- Results in: ~/Documents/mdpaste/filename.png

-- Project-based organization
path_prefix = function()
  local project = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return project .. "/" .. os.date("%Y-%m")
end
-- Results in: ~/Documents/mdpaste/myproject/2025-08/filename.png

-- Week-based organization
path_prefix = function()
  return os.date("%Y/week-%W")
end
-- Results in: ~/Documents/mdpaste/2025/week-33/filename.png
```

#### Custom Filename Generator Examples

```lua
-- UUID-based filenames
filename_generator = function(file_type, original_name, dir_path)
  if file_type == "image" then
    return vim.fn.system("uuidgen"):gsub("\n", "")
  else
    return original_name or vim.fn.system("uuidgen"):gsub("\n", "")
  end
end
-- Results in: 550E8400-E29B-41D4-A716-446655440000.png

-- Sequential numbering
filename_generator = function(file_type, original_name, dir_path)
  -- Find highest numbered image file
  local max_num = 0
  if vim.fn.isdirectory(dir_path) == 1 then
    local files = vim.fn.globpath(dir_path, file_type .. "_*", false, true)
    for _, file in ipairs(files) do
      local name = vim.fn.fnamemodify(file, ":t:r")
      local num = tonumber(name:match(file_type .. "_(%d+)"))
      if num and num > max_num then
        max_num = num
      end
    end
  end
  return file_type .. "_" .. (max_num + 1)
end
-- Results in: image_1.png, image_2.png, file_1.txt, file_2.pdf, etc.

-- Hash-based naming (for deduplication)
filename_generator = function(file_type, original_name, dir_path)
  if file_type == "image" then
    return vim.fn.sha256(tostring(os.time()))
  else
    return original_name or vim.fn.sha256(tostring(os.time()))
  end
end
-- Results in: a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3.png
```

### Output Examples

**Text clipboard:**

```
Hello, World!
```

**Image clipboard:**

```markdown
![[./2025/08/2025-08-19-143052.png]]
```

**File clipboard (embeddable):**

```markdown
![[./2025/08/document.pdf]]
![[./2025/08/video.mp4]]
```

**File clipboard (non-embeddable):**

```markdown
[document.txt](./2025/08/document.txt)
[data.json](./2025/08/data.json)
```

## File Type Support

### Embeddable Files (use `![[]]` format)

- **Images**: `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.webp`, `.svg`, `.tiff`, `.tif`
- **Videos**: `.mp4`, `.avi`, `.mov`, `.mkv`, `.webm`, `.flv`, `.wmv`, `.m4v`
- **PDFs**: `.pdf`

### Regular Files (use `[]()` format)

- All other file types

## Troubleshooting

### pngpaste not found

Install pngpaste: `brew install pngpaste`

### Permission denied errors

Ensure Neovim has the necessary permissions to access clipboard and write to the configured directory.

### AppleScript execution fails

Grant Terminal or your terminal app accessibility permissions in System Preferences > Security & Privacy > Privacy > Accessibility.
