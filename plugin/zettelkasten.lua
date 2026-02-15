if vim.g.loaded_zettelkasten then
  return
end
vim.g.loaded_zettelkasten = true

vim.api.nvim_create_user_command("ZettelAdd", function()
  require("zettelkasten").add_entry()
end, {
  desc = "Add a new zettel entry at the top of the current .zettel file",
})

vim.api.nvim_create_user_command("ZettelSearch", function()
  require("zettelkasten").search_entries()
end, {
  desc = "Search and filter zettel entries by tags",
})
