# telescope-luasnip

This plugin adds a [LuaSnip](https://github.com/L3MON4D3/LuaSnip) snippet source picker to the already-awesome Neovim [Telescope plugin](https://github.com/nvim-telescope/telescope.nvim).

Shows snippets loaded from files (via `loaders_store_source = true`) for the
current buffer's filetype — uses the same filetype logic as
`luasnip.available()`, respecting `ft_func`, `filetype_extend`, and treesitter
injection languages.

Selecting a snippet jumps directly to its source file and line.

This is a port of [fhill2/telescope-ultisnips.nvim](https://github.com/fhill2/telescope-ultisnips.nvim) from Ultisnips to LuaSnip. Thanks for the simple great idea!

![telescope-luasnip.nvim in action](screenshot.png)

## Requirements

- [LuaSnip](https://github.com/L3MON4D3/LuaSnip) (required)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (required)

## Setup

Install the plugin using your favourite package manager.

```lua
-- lazy.nvim
{
  "benfowler/telescope-luasnip.nvim",
  dependencies = { "L3MON4D3/LuaSnip", "nvim-telescope/telescope.nvim" },
}
```

Then load the extension after `require('telescope').setup()`:

```lua
require('telescope').load_extension('luasnip')
```

### Important: source tracking must be enabled

The picker relies on `loaders_store_source = true` in LuaSnip to know where
each snippet came from:

```lua
require("luasnip").config.setup({
  loaders_store_source = true,
})
```

## Usage

```vim
:Telescope luasnip
```

```lua
require('telescope').extensions.luasnip.luasnip {}
```

## Configuration

The plugin works fine as-is and requires no further configuration.

### Search customization

You can provide a custom `search` function to control what text is used for
fuzzy matching. The function receives an entry with these fields:

| Field      | Description                          |
|------------|--------------------------------------|
| `snippet`  | LuaSnip snippet object               |
| `ft`       | `"snip"` or `"auto"`                 |
| `filetype` | The filetype the snippet belongs to  |
| `filename` | Source file path                      |
| `lnum`     | Source line number                    |

Example:

```lua
require('telescope').setup {
  extensions = {
    luasnip = {
      search = function(entry)
        return entry.snippet.trigger .. " " .. entry.filetype
      end,
    },
  },
}
```

Default search text is: `trigger + name + ft + description`.

### Theme

```lua
require('telescope').setup {
  luasnip = require("telescope.themes").get_dropdown({
    border  = false,
    preview = { check_mime_type = true },
  }),
}
```

## Help!

Is there something not quite right or could be improved?  Log an issue with a
minimal reproduction, or better yet, raise a PR.

<!-- markdownlint-disable-file -->
