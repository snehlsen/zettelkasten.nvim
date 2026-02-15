local M = {}

-- Get today's date in YYYY-MM-DD format
function M.get_date()
  return os.date("%Y-%m-%d")
end

-- Validate a single tag: only letters, numbers, underscores
function M.is_valid_tag(tag)
  return tag:match("^[%w_]+$") ~= nil
end

-- Parse tags from a header line like "2026-01-01 !project_a !peter"
-- Returns the list of tags (without ! prefix)
function M.parse_header_tags(line)
  local tags = {}
  for tag in line:gmatch("!([%w_]+)") do
    table.insert(tags, tag)
  end
  return tags
end

-- Parse all entries from buffer lines.
-- Returns a list of { line_nr = <1-based>, date = <string>, tags = {}, content = {} }
function M.parse_entries(lines)
  local entries = {}
  local i = 1
  while i <= #lines do
    -- Skip blank lines
    if lines[i]:match("^%s*$") then
      i = i + 1
    else
      -- Try to match a header line: YYYY-MM-DD optionally followed by tags
      local date = lines[i]:match("^(%d%d%d%d%-%d%d%-%d%d)")
      if date then
        local entry = {
          line_nr = i,
          date = date,
          tags = M.parse_header_tags(lines[i]),
          content = {},
        }
        -- Collect content lines until blank line or next header or EOF
        i = i + 1
        while i <= #lines and not lines[i]:match("^%s*$") do
          table.insert(entry.content, lines[i])
          i = i + 1
        end
        table.insert(entries, entry)
      else
        -- Non-header, non-blank line: skip (shouldn't happen in well-formed files)
        i = i + 1
      end
    end
  end
  return entries
end

-- Collect all unique tags from buffer lines
function M.collect_tags(lines)
  local tag_set = {}
  local tags = {}
  for _, line in ipairs(lines) do
    for tag in line:gmatch("!([%w_]+)") do
      if not tag_set[tag] then
        tag_set[tag] = true
        table.insert(tags, tag)
      end
    end
  end
  table.sort(tags)
  return tags
end

-- Filter entries that contain ALL of the given tags
function M.filter_entries_by_tags(entries, filter_tags)
  local result = {}
  for _, entry in ipairs(entries) do
    local tag_set = {}
    for _, t in ipairs(entry.tags) do
      tag_set[t] = true
    end
    local match = true
    for _, ft in ipairs(filter_tags) do
      if not tag_set[ft] then
        match = false
        break
      end
    end
    if match then
      table.insert(result, entry)
    end
  end
  return result
end

-- Format an entry for display in picker
function M.format_entry(entry)
  local tag_str = ""
  if #entry.tags > 0 then
    tag_str = " !" .. table.concat(entry.tags, " !")
  end
  local preview = ""
  if #entry.content > 0 then
    preview = " | " .. entry.content[1]
  end
  return entry.date .. tag_str .. preview
end

-- Add a new entry at the top of the current buffer.
-- Inserts date + tags header, then positions cursor on content line in insert mode.
function M.add_entry()
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.zettel$") then
    vim.notify("ZettelAdd: current file is not a .zettel file", vim.log.levels.WARN)
    return
  end

  vim.ui.input({ prompt = "Tags (space-separated): " }, function(input)
    if input == nil then
      return
    end

    local date = M.get_date()
    local header = date

    -- Parse and validate tags
    local raw_tags = vim.split(vim.fn.trim(input), "%s+", { trimempty = true })
    local valid_tags = {}
    for _, tag in ipairs(raw_tags) do
      if M.is_valid_tag(tag) then
        table.insert(valid_tags, "!" .. tag)
      elseif tag ~= "" then
        vim.notify("ZettelAdd: skipping invalid tag: " .. tag, vim.log.levels.WARN)
      end
    end

    if #valid_tags > 0 then
      header = header .. " " .. table.concat(valid_tags, " ")
    end

    -- Check if buffer has content; if so, add blank line separator
    local existing = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local has_content = false
    for _, line in ipairs(existing) do
      if line ~= "" then
        has_content = true
        break
      end
    end

    local new_lines
    if has_content then
      new_lines = { header, "", "" }
    else
      new_lines = { header, "" }
    end

    -- Insert at top of file
    vim.api.nvim_buf_set_lines(0, 0, 0, false, new_lines)

    -- Position cursor on the content line (line 2, 1-indexed) and enter insert mode
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd("startinsert")
  end)
end

-- Search entries by tags in the current buffer.
function M.search_entries()
  local bufname = vim.api.nvim_buf_get_name(0)
  if not bufname:match("%.zettel$") then
    vim.notify("ZettelSearch: current file is not a .zettel file", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local all_tags = M.collect_tags(lines)

  if #all_tags == 0 then
    vim.notify("ZettelSearch: no tags found in current file", vim.log.levels.INFO)
    return
  end

  local tag_display = table.concat(all_tags, ", ")
  vim.ui.input({ prompt = "Filter by tags (" .. tag_display .. "): " }, function(input)
    if input == nil or vim.fn.trim(input) == "" then
      return
    end

    -- Parse comma-separated or space-separated tags
    local raw = vim.fn.trim(input)
    local filter_tags = {}
    for tag in raw:gmatch("[%w_]+") do
      table.insert(filter_tags, tag)
    end

    if #filter_tags == 0 then
      return
    end

    local entries = M.parse_entries(lines)
    local matches = M.filter_entries_by_tags(entries, filter_tags)

    if #matches == 0 then
      vim.notify("ZettelSearch: no entries match the given tags", vim.log.levels.INFO)
      return
    end

    -- Build selection list
    local items = {}
    for _, entry in ipairs(matches) do
      table.insert(items, M.format_entry(entry))
    end

    vim.ui.select(items, { prompt = "Select entry:" }, function(_, idx)
      if idx then
        local target = matches[idx].line_nr
        vim.api.nvim_win_set_cursor(0, { target, 0 })
      end
    end)
  end)
end

function M.setup(opts)
  -- Reserved for future configuration
end

return M
