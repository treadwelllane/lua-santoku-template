local test = require("santoku.test")

local err = require("santoku.error")
local assert = err.assert

local fs = require("santoku.fs")
local str = require("santoku.string")

local anchor = "test/spec/santoku/template_anchor.lua"

local function findroot ()
  local dir = fs.cwd()
  while dir and dir ~= "" do
    if fs.isfile(fs.join(dir, "README.md")) and fs.isfile(fs.join(dir, anchor)) then
      return dir
    end
    dir = fs.dirname(dir)
  end
end

test("README reproduces the anchor spec verbatim", function ()
  local root = findroot()
  assert(root ~= nil,
    "could not find a directory containing both README.md and " .. anchor,
    "searched upward from " .. fs.cwd())
  local readme = fs.readfile(fs.join(root, "README.md"))
  local spec = fs.readfile(fs.join(root, anchor))
  assert(str.find(readme, "```lua\n" .. spec .. "```", 1, true) ~= nil,
    "README.md drifted from " .. anchor,
    "the README must contain the anchor spec verbatim inside a ```lua fence",
    "update README.md or the anchor spec so they match, then rerun toku test")
end)
