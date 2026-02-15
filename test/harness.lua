-- test/harness.lua
-- Minimal reusable test framework for Neovim plugin integration tests.
-- Provides describe/it structure, assertion helpers, and exit code management.

local H = {}

H._results = {}
H._current_test = nil
H._fail_count = 0

function H.describe(name, fn)
  print("== " .. name .. " ==")
  fn()
end

function H.it(name, fn)
  H._current_test = name
  local ok, err = pcall(fn)
  if ok then
    print("  PASS: " .. name)
    table.insert(H._results, { name = name, status = "pass" })
  else
    print("  FAIL: " .. name)
    print("        " .. tostring(err))
    table.insert(H._results, { name = name, status = "fail", err = tostring(err) })
    H._fail_count = H._fail_count + 1
  end
end

function H.assert_eq(got, expected, msg)
  if got ~= expected then
    error(string.format(
      "%s: expected %s, got %s",
      msg or "assert_eq",
      vim.inspect(expected),
      vim.inspect(got)
    ), 2)
  end
end

function H.assert_truthy(val, msg)
  if not val then
    error(string.format("%s: expected truthy, got %s", msg or "assert_truthy", vim.inspect(val)), 2)
  end
end

function H.assert_contains(tbl, value, msg)
  for _, v in ipairs(tbl) do
    if v == value then
      return
    end
  end
  error(string.format(
    "%s: value %s not found in table",
    msg or "assert_contains",
    vim.inspect(value)
  ), 2)
end

function H.assert_no_error(fn, msg)
  local ok, err = pcall(fn)
  if not ok then
    error(string.format("%s: unexpected error: %s", msg or "assert_no_error", tostring(err)), 2)
  end
end

function H.finish()
  print("")
  local total = #H._results
  local passed = total - H._fail_count
  print(string.format("Results: %d/%d passed", passed, total))
  if H._fail_count > 0 then
    print("FAILED")
    vim.cmd("cquit! 1")
  else
    print("OK")
    vim.cmd("qall!")
  end
end

return H
