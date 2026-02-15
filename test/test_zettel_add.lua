local H = require("harness")

H.describe("ZettelAdd Command", function()
  local zk = require("zettelkasten")

  H.it("warns when file is not .zettel", function()
    vim.cmd("enew!")
    -- Buffer has no name (not a .zettel file)
    local warned = false
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      if msg:match("not a .zettel file") then
        warned = true
      end
    end
    zk.add_entry()
    vim.notify = orig_notify
    H.assert_truthy(warned, "should warn about non-.zettel file")
  end)

  H.it("inserts date header into empty .zettel buffer", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_add.zettel")

    -- Stub vim.ui.input to provide tags
    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback("project_a meeting")
    end

    zk.add_entry()
    vim.cmd("stopinsert")

    vim.ui.input = orig_input

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    -- First line should be date + tags
    local date = zk.get_date()
    H.assert_eq(lines[1], date .. " !project_a !meeting", "header line with date and tags")
  end)

  H.it("inserts header with no tags when input is empty", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_add_notags.zettel")

    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback("")
    end

    zk.add_entry()
    vim.cmd("stopinsert")

    vim.ui.input = orig_input

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local date = zk.get_date()
    H.assert_eq(lines[1], date, "header line with date only")
  end)

  H.it("adds blank line separator when buffer has existing content", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_add_existing.zettel")

    -- Pre-populate buffer with an existing entry
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "2026-01-01 !old_tag",
      "Old content here",
    })

    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback("new_tag")
    end

    zk.add_entry()
    vim.cmd("stopinsert")

    vim.ui.input = orig_input

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local date = zk.get_date()

    -- Line 1: new header
    H.assert_eq(lines[1], date .. " !new_tag", "new header at top")
    -- Line 2: empty (content line placeholder)
    H.assert_eq(lines[2], "", "content line is empty")
    -- Line 3: blank separator
    H.assert_eq(lines[3], "", "blank line separator")
    -- Line 4+: old content preserved
    H.assert_eq(lines[4], "2026-01-01 !old_tag", "old header preserved")
    H.assert_eq(lines[5], "Old content here", "old content preserved")
  end)

  H.it("does nothing when user cancels input", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_add_cancel.zettel")

    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback(nil) -- User pressed Escape
    end

    zk.add_entry()

    vim.ui.input = orig_input

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    H.assert_eq(#lines, 1, "buffer unchanged")
    H.assert_eq(lines[1], "", "still empty")
  end)

  H.it("skips invalid tags with warning", function()
    vim.cmd("enew!")
    vim.api.nvim_buf_set_name(0, "/tmp/test_add_invalid.zettel")

    local warnings = {}
    local orig_notify = vim.notify
    vim.notify = function(msg, level)
      table.insert(warnings, msg)
    end

    local orig_input = vim.ui.input
    vim.ui.input = function(opts, callback)
      callback("good_tag bad-tag also_good")
    end

    zk.add_entry()
    vim.cmd("stopinsert")

    vim.ui.input = orig_input
    vim.notify = orig_notify

    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local date = zk.get_date()
    H.assert_eq(lines[1], date .. " !good_tag !also_good", "only valid tags in header")

    -- Check that a warning was issued
    local found_warning = false
    for _, w in ipairs(warnings) do
      if w:match("bad%-tag") then
        found_warning = true
      end
    end
    H.assert_truthy(found_warning, "warning about invalid tag")
  end)
end)

H.finish()
