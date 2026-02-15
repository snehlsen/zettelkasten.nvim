local H = require("harness")

H.describe("Zettelkasten Parsing", function()
  local zk = require("zettelkasten")

  -- Tag validation
  H.it("validates correct tags", function()
    H.assert_truthy(zk.is_valid_tag("project_a"), "alphanumeric with underscore")
    H.assert_truthy(zk.is_valid_tag("meeting"), "simple word")
    H.assert_truthy(zk.is_valid_tag("v2"), "with number")
    H.assert_truthy(zk.is_valid_tag("ABC"), "uppercase")
  end)

  H.it("rejects invalid tags", function()
    H.assert_eq(zk.is_valid_tag("has space"), false, "space in tag")
    H.assert_eq(zk.is_valid_tag("has-dash"), false, "dash in tag")
    H.assert_eq(zk.is_valid_tag("has.dot"), false, "dot in tag")
    H.assert_eq(zk.is_valid_tag(""), false, "empty string")
  end)

  -- Header tag parsing
  H.it("parses tags from header line", function()
    local tags = zk.parse_header_tags("2026-01-01 !project_a !peter")
    H.assert_eq(#tags, 2, "two tags")
    H.assert_eq(tags[1], "project_a", "first tag")
    H.assert_eq(tags[2], "peter", "second tag")
  end)

  H.it("parses header with no tags", function()
    local tags = zk.parse_header_tags("2026-01-01")
    H.assert_eq(#tags, 0, "no tags")
  end)

  -- Entry parsing
  H.it("parses a single entry", function()
    local lines = {
      "2026-01-01 !project_a !peter",
      "Had a talk with Peter about feature X",
      "link: http://example.com",
    }
    local entries = zk.parse_entries(lines)
    H.assert_eq(#entries, 1, "one entry")
    H.assert_eq(entries[1].date, "2026-01-01", "date")
    H.assert_eq(entries[1].line_nr, 1, "line number")
    H.assert_eq(#entries[1].tags, 2, "two tags")
    H.assert_eq(entries[1].tags[1], "project_a", "first tag")
    H.assert_eq(entries[1].tags[2], "peter", "second tag")
    H.assert_eq(#entries[1].content, 2, "two content lines")
    H.assert_eq(entries[1].content[1], "Had a talk with Peter about feature X", "content line 1")
  end)

  H.it("parses multiple entries separated by blank lines", function()
    local lines = {
      "2026-01-01 !project_a !peter",
      "Talk with Peter",
      "",
      "2026-01-02 !proj_b !meeting",
      "Team standup notes",
      "Discussed roadmap",
      "",
      "2026-01-03 !project_a !release",
      "Version 2.0 released",
    }
    local entries = zk.parse_entries(lines)
    H.assert_eq(#entries, 3, "three entries")
    H.assert_eq(entries[1].date, "2026-01-01", "first date")
    H.assert_eq(entries[2].date, "2026-01-02", "second date")
    H.assert_eq(entries[3].date, "2026-01-03", "third date")
    H.assert_eq(entries[2].line_nr, 4, "second entry line nr")
    H.assert_eq(#entries[2].content, 2, "second entry content lines")
  end)

  H.it("handles multiple blank lines between entries", function()
    local lines = {
      "2026-01-01 !a",
      "Content A",
      "",
      "",
      "",
      "2026-01-02 !b",
      "Content B",
    }
    local entries = zk.parse_entries(lines)
    H.assert_eq(#entries, 2, "two entries despite multiple blanks")
  end)

  H.it("parses entry without tags", function()
    local lines = {
      "2026-01-01",
      "Just a note",
    }
    local entries = zk.parse_entries(lines)
    H.assert_eq(#entries, 1, "one entry")
    H.assert_eq(#entries[1].tags, 0, "no tags")
    H.assert_eq(entries[1].content[1], "Just a note", "content")
  end)

  -- Tag collection
  H.it("collects unique tags from buffer lines", function()
    local lines = {
      "2026-01-01 !project_a !peter",
      "Content",
      "",
      "2026-01-02 !project_a !meeting",
      "More content",
    }
    local tags = zk.collect_tags(lines)
    H.assert_eq(#tags, 3, "three unique tags")
    -- Tags are sorted
    H.assert_eq(tags[1], "meeting", "first sorted tag")
    H.assert_eq(tags[2], "peter", "second sorted tag")
    H.assert_eq(tags[3], "project_a", "third sorted tag")
  end)

  -- Filtering
  H.it("filters entries by single tag", function()
    local entries = {
      { tags = { "project_a", "peter" }, date = "2026-01-01", line_nr = 1, content = {} },
      { tags = { "proj_b", "meeting" }, date = "2026-01-02", line_nr = 4, content = {} },
      { tags = { "project_a", "release" }, date = "2026-01-03", line_nr = 7, content = {} },
    }
    local matches = zk.filter_entries_by_tags(entries, { "project_a" })
    H.assert_eq(#matches, 2, "two matches for project_a")
    H.assert_eq(matches[1].date, "2026-01-01", "first match")
    H.assert_eq(matches[2].date, "2026-01-03", "second match")
  end)

  H.it("filters entries by multiple tags (AND logic)", function()
    local entries = {
      { tags = { "project_a", "peter" }, date = "2026-01-01", line_nr = 1, content = {} },
      { tags = { "project_a", "meeting" }, date = "2026-01-02", line_nr = 4, content = {} },
    }
    local matches = zk.filter_entries_by_tags(entries, { "project_a", "peter" })
    H.assert_eq(#matches, 1, "one match for project_a AND peter")
    H.assert_eq(matches[1].date, "2026-01-01", "correct match")
  end)

  H.it("returns empty when no entries match", function()
    local entries = {
      { tags = { "a" }, date = "2026-01-01", line_nr = 1, content = {} },
    }
    local matches = zk.filter_entries_by_tags(entries, { "nonexistent" })
    H.assert_eq(#matches, 0, "no matches")
  end)

  -- Format entry
  H.it("formats entry with tags and content", function()
    local entry = {
      date = "2026-01-01",
      tags = { "project_a", "peter" },
      content = { "Had a talk with Peter" },
      line_nr = 1,
    }
    local formatted = zk.format_entry(entry)
    H.assert_eq(formatted, "2026-01-01 !project_a !peter | Had a talk with Peter", "formatted entry")
  end)

  H.it("formats entry without tags", function()
    local entry = {
      date = "2026-01-01",
      tags = {},
      content = { "Just a note" },
      line_nr = 1,
    }
    local formatted = zk.format_entry(entry)
    H.assert_eq(formatted, "2026-01-01 | Just a note", "formatted entry no tags")
  end)

  H.it("formats entry without content", function()
    local entry = {
      date = "2026-01-01",
      tags = { "empty" },
      content = {},
      line_nr = 1,
    }
    local formatted = zk.format_entry(entry)
    H.assert_eq(formatted, "2026-01-01 !empty", "formatted entry no content")
  end)

  -- Date format
  H.it("get_date returns YYYY-MM-DD format", function()
    local date = zk.get_date()
    H.assert_truthy(date:match("^%d%d%d%d%-%d%d%-%d%d$"), "date format YYYY-MM-DD")
  end)
end)

H.finish()
