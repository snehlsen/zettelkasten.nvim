-- test/run_all.lua
-- Orchestrator: discovers test_*.lua files and runs each in an isolated nvim process.
-- Usage: nvim --clean -l test/run_all.lua

local script_path = debug.getinfo(1, "S").source:sub(2)
local plugin_dir = vim.fn.fnamemodify(script_path, ":h:h")
local test_dir = plugin_dir .. "/test"

-- Discover test files
local test_files = vim.fn.glob(test_dir .. "/test_*.lua", false, true)
table.sort(test_files)

if #test_files == 0 then
  print("No test files found in " .. test_dir)
  os.exit(1)
end

local failed = {}
local passed = 0

print("Running " .. #test_files .. " test file(s)...\n")

for _, test_file in ipairs(test_files) do
  local short_name = vim.fn.fnamemodify(test_file, ":t")
  io.write("--- " .. short_name .. " ---\n")
  io.flush()

  local cmd = string.format(
    "nvim --clean --headless"
      .. " --cmd %s"
      .. " -c %s"
      .. " -c %s",
    vim.fn.shellescape("set runtimepath+=" .. plugin_dir),
    vim.fn.shellescape("lua package.path = '" .. test_dir .. "/?.lua;' .. package.path"),
    vim.fn.shellescape("luafile " .. test_file)
  )

  local exit_code = os.execute(cmd)
  if exit_code == 0 or exit_code == true then
    passed = passed + 1
  else
    table.insert(failed, short_name)
  end
  print("")
end

print("========================================")
print(string.format("Total: %d  Passed: %d  Failed: %d", #test_files, passed, #failed))
if #failed > 0 then
  print("Failed tests:")
  for _, name in ipairs(failed) do
    print("  - " .. name)
  end
  os.exit(1)
else
  print("All tests passed.")
  os.exit(0)
end
