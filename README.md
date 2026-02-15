# zettelkasten.nvim

A minimal Neovim plugin for managing timestamped, tagged text entries in `.zettel` files.

## Format

A `.zettel` file is plain text with entries separated by blank lines. Each entry starts with a date header followed by optional tags, then content on subsequent lines:

```
2026-01-15 !meeting !project_a
Discussed the roadmap for Q1 with the team
Action items: finalize spec, update timeline

2026-01-16 !release
Version 2.0 shipped successfully
```

Tags are prefixed with `!` and may contain letters, numbers, and underscores.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "snehlsen/zettelkasten.nvim" }
```

No configuration is required. The plugin loads automatically.

## Commands

### `:ZettelAdd`

Adds a new entry at the top of the current `.zettel` file. Inserts today's date, prompts for tags (space-separated, without the `!` prefix), and positions the cursor on the content line in insert mode.

### `:ZettelSearch`

Filters entries by tags. Shows all available tags in the file, prompts for one or more tags to filter by (comma or space-separated), then displays matching entries in a picker. Selecting an entry jumps the cursor to it. Filtering uses AND logic — entries must contain all specified tags to match.

## Keymaps

The plugin does not set any keymaps. Example configuration:

```lua
vim.keymap.set("n", "<leader>za", ":ZettelAdd<CR>")
vim.keymap.set("n", "<leader>zs", ":ZettelSearch<CR>")
```

## Running Tests

```sh
make test
make test-verbose
make test-file FILE=test/test_zettel_parse.lua
```
