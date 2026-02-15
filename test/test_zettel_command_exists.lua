local H = require("harness")

H.describe("Zettelkasten Command Registration", function()
  H.it(":ZettelAdd command exists", function()
    local exists = vim.fn.exists(":ZettelAdd")
    H.assert_eq(exists, 2, ":ZettelAdd exists")
  end)

  H.it(":ZettelSearch command exists", function()
    local exists = vim.fn.exists(":ZettelSearch")
    H.assert_eq(exists, 2, ":ZettelSearch exists")
  end)
end)

H.finish()
