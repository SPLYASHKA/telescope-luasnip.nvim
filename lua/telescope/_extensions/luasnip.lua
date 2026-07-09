local has_telescope, telescope = pcall(require, 'telescope')
if not has_telescope then
  error 'This plugins requires nvim-telescope/telescope.nvim'
end

-- stylua: ignore start
local action_state  = require("telescope.actions.state")
local actions       = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local finders       = require("telescope.finders")
local pickers       = require("telescope.pickers")
local previewers    = require("telescope.previewers")
local conf          = require("telescope.config").values
local ext_conf      = require("telescope._extensions")
-- stylua: ignore end

local Source = require 'luasnip.session.snippet_collection.source'
local ls = require 'luasnip'
local snip_location = require 'luasnip.extras.snip_location'

local M = {}

local filter_null = function(str, default)
  return str and str or (default and default or '')
end

local filter_description = function(name, description)
  local result = ''
  if description and #description > 1 then
    for _, line in ipairs(description) do
      result = result .. line .. ' '
    end
  elseif name and description and description[1] ~= name then
    result = description[1]
  end
  return result
end

local default_search_text = function(entry)
  return filter_null(entry.snippet.trigger)
    .. ' '
    .. filter_null(entry.snippet.name)
    .. ' '
    .. entry.ft
    .. ' '
    .. filter_description(entry.snippet.name, entry.snippet.description)
end

local function collect()
  local results = {}
  local fts = ls.get_snippet_filetypes()
  for _, ft in ipairs(fts) do
    for _, snip in ipairs(ls.get_snippets(ft)) do
      local src = Source.get(snip)
      if src then
        table.insert(results, {
          ft = 'snip',
          snippet = snip,
          filetype = ft,
          filename = src.file,
          lnum = src.line or 1,
        })
      end
    end
    for _, snip in ipairs(ls.get_snippets(ft, { type = 'autosnippets' })) do
      local src = Source.get(snip)
      if src then
        table.insert(results, {
          ft = 'auto',
          snippet = snip,
          filetype = ft,
          filename = src.file,
          lnum = src.line or 1,
        })
      end
    end
  end
  return results
end

local _opts = {
  preview = {
    check_mime_type = true,
  },
}
M.opts = _opts

M.luasnip_fn = function(opts)
  opts = vim.tbl_extend('keep', opts or {}, M.opts or _opts)

  local items = collect()
  if vim.tbl_isempty(items) then
    vim.notify('No snippet sources found. Set loaders_store_source = true', vim.log.levels.WARN)
    return
  end

  table.sort(items, function(a, b)
    if a.ft ~= b.ft then
      return a.ft > b.ft
    elseif a.snippet.name ~= b.snippet.name then
      return a.snippet.name > b.snippet.name
    else
      return a.snippet.trigger > b.snippet.trigger
    end
  end)

  local displayer = entry_display.create {
    separator = ' ',
    items = { { width = 6 }, { width = 24 }, { width = 16 }, { remaining = true } },
  }

  local make_display = function(entry)
    return displayer {
      entry.value.ft,
      entry.value.snippet.name,
      { entry.value.snippet.trigger, 'TelescopeResultsNumber' },
      string.format('%s:%s', vim.fn.fnamemodify(entry.value.filename, ':~:.'), entry.value.lnum),
    }
  end

  pickers
    .new(opts, {
      prompt_title = 'LuaSnip Sources',
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          local search_fn = ext_conf._config.luasnip and ext_conf._config.luasnip.search or default_search_text
          return {
            value = entry,
            filename = entry.snippet.trigger,
            display = make_display,
            text = string.format(' %s | %s | %s', entry.ft, entry.snippet.name, entry.snippet.description[1] or ''),
            ordinal = search_fn(entry),
            preview_command = function(_, bufnr)
              if opts.preview.check_mime_type then
                vim.api.nvim_buf_set_option(bufnr, 'filetype', entry.filetype)
              end
              local ds = entry.snippet:get_docstring()
              if type(ds) == 'string' then
                ds = vim.split(ds, '\n')
              end
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, ds)
            end,
          }
        end,
      },
      previewer = previewers.display_content.new(opts),
      sorter = conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          snip_location.jump_to_snippet(action_state.get_selected_entry().value.snippet)
        end)
        return true
      end,
    })
    :find()
end

-- stylua: ignore start
return telescope.register_extension({
  setup = function(ext_opts, opts)
    M.opts = vim.tbl_extend('keep', ext_opts or {}, opts or {}, M.opts or _opts)
  end,
  exports = {
    luasnip = M.luasnip_fn,
  },
})
-- stylua: ignore end
