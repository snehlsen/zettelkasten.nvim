local H = require("harness")

H.describe("ZettelSearch Command", function()
  local zk = require("zettelkasten")

  H.it("warns when file is not .zettel", function()
    vim.cmd("enew!")
    local warned = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("not a .zettel file") then
        warned = true
      end
    end
    zk.search_entries()
    vim.notify = orig_notify
    H.assert_truthy(warned, "should warn about non-.zettel file")
  end)

  H.it("notifies when no tags in file", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_search_empty.zettel")

    local notified = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("no tags found") then
        notified = true
      end
    end
    zk.search_entries()
    vim.notify = orig_notify
    H.assert_truthy(notified, "should notify about no tags")
  end)

  H.it("notifies when no entries match filter", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_search_nomatch.zettel")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "2026-01-01 !project_a",
      "Some content",
    })

    local notified = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("no entries match") then
        notified = true
      end
    end

    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback("nonexistent_tag")
    end

    zk.search_entries()

    vim.ui.input = orig_input
    vim.notify = orig_notify
    H.assert_truthy(notified, "should notify no matches")
  end)

  H.it("jumps to selected entry", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_search_jump.zettel")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "2026-01-01 !project_a !peter",
      "Talk with Peter",
      "",
      "2026-01-02 !proj_b !meeting",
      "Team standup notes",
      "",
      "2026-01-03 !project_a !release",
      "Version 2.0 released",
    })

    -- Move cursor to top
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local orig_input = vim.ui.input
    local orig_select = vim.ui.select
    vim.ui.input = function(opts, callback)
      callback("project_a")
    end
    vim.ui.select = function(items, opts, callback)
      -- Should have 2 matches (entries 1 and 3)
      H.assert_eq(#items, 2, "two matching entries")
      -- Select the second one (entry at line 7)
      callback(items[2], 2)
    end

    zk.search_entries()

    vim.ui.input = orig_input
    vim.ui.select = orig_select

    local cursor = vim.api.nvim_win_get_cursor(0)
    H.assert_eq(cursor[1], 7, "cursor jumped to line 7")
  end)

  H.it("does nothing when user cancels tag input", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_search_cancel.zettel")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "2026-01-01 !tag_a",
      "Content",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback(nil) -- User pressed Escape
    end

    zk.search_entries()

    vim.ui.input = orig_input

    local cursor = vim.api.nvim_win_get_cursor(0)
    H.assert_eq(cursor[1], 1, "cursor unchanged after cancel")
  end)

  H.it("does nothing when user cancels selection", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_search_cancel_sel.zettel")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "2026-01-01 !tag_a",
      "Content",
    })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    local orig_input = vim.ui.input
    local orig_select = vim.ui.select
    vim.ui.input = function(opts, callback)
      callback("tag_a")
    end
    vim.ui.select = function(items, opts, callback)
      callback(nil, nil) -- User cancelled selection
    end

    zk.search_entries()

    vim.ui.input = orig_input
    vim.ui.select = orig_select

    local cursor = vim.api.nvim_win_get_cursor(0)
    H.assert_eq(cursor[1], 1, "cursor unchanged after cancel selection")
  end)

  H.it("handles comma-separated tag input", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_search_comma.zettel")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "2026-01-01 !project_a !peter",
      "Talk with Peter",
      "",
      "2026-01-02 !project_a !meeting",
      "Team standup",
    })

    local selected_items = nil
    local orig_input = vim.ui.input
    local orig_select = vim.ui.select
    vim.ui.input = function(opts, callback)
      callback("project_a, peter")
    end
    vim.ui.select = function(items, opts, callback)
      selected_items = items
      callback(items[1], 1)
    end

    zk.search_entries()

    vim.ui.input = orig_input
    vim.ui.select = orig_select

    -- Only entry 1 has both project_a AND peter
    H.assert_eq(#selected_items, 1, "one match for project_a AND peter")
  end)
end)

H.finish()
