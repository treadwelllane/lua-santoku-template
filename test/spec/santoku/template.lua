local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal

local template = require("santoku.template")
local compile = template.compile
local compilefile = template.compilefile

local fs = require("santoku.fs")

test("should compile a template string", function ()
  local render = compile("<title><% return title %></title>")
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "<title>Hello, World!</title>"))
end)

test("should handle multiple replacements", function ()
  local render = compile("<title><% return title %> <% return title %></title>")
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "<title>Hello, World! Hello, World!</title>"))
end)

test("should handle trailing characters", function ()
  local render = compile([[
    <template
      data-api="/api/ping"
      data-method="get"
      <% local tbl = require("santoku.table")
        local arr = require("santoku.array")
        local format = string.format
        return arr.concat(arr.map(tbl.entries(redirects), function (e)
          return format("data-handler-%d=\"redirect:%s\"", e[1], e[2])
        end)) %>>
    </template>
  ]])
  local str = render({ redirects = { [403] = "/login" } }, _G)
  assert(eq(str, [[
    <template
      data-api="/api/ping"
      data-method="get"
      data-handler-403="redirect:/login">
    </template>]]))
end)

test("file chunks share environment", function ()
  local render = compile("<% a = '1' %><% return a %>")
  assert(eq("1", render()))
end)

test("render compiled template multiple times", function ()
  local t = compile("<% return 'a' %>")
  assert(eq("a", t()))
  assert(eq("a", t()))
  assert(eq("a", t()))
end)

test("nil blocks collapse surrounding blank lines", function ()
  local render = compile("one\n<% %>\ntwo")
  assert(eq("one\ntwo", render()))
end)

test("readfile provided via env", function ()
  local render = compile("<% return readfile('test/res/template/title.html') %>")
  local str = render({ readfile = fs.readfile, title = "Hello, World!" })
  assert(eq(str, "<% return title %>\n"))
end)

test("compilefile works", function ()
  local render = compilefile("test/res/template/title.html")
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "Hello, World!"))
end)

test("_prefix is available", function ()
  local render = compile("    <% return _prefix %>")
  assert(eq("    ", render()))
end)

test("_prefix reflects indentation", function ()
  local render = compile("line\n      <% return _prefix %>")
  assert(eq("line\n            ", render()))
end)

test("_prefix is empty for inline blocks", function ()
  local render = compile("text <% return _prefix %>")
  assert(eq("text ", render()))
end)

test("_prefix used for indentation", function ()
  local str = require("santoku.string")
  local render = compile("  <% return str.gsub('a\\nb\\nc', '\\n', '\\n' .. _prefix) %>")
  assert(eq("  a\n  b\n  c", render({ str = str })))
end)
