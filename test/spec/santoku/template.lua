local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal

local inherit = require("santoku.inherit")
local pushindex = inherit.pushindex

local tbl = require("santoku.table")
local teq = tbl.equals

local template = require("santoku.template")
local compile = template.compile
local compilefile = template.compilefile
-- local serialize_deps = template.serialize_deps

local fs = require("santoku.fs")
local runfile = fs.runfile

test("should compile a template string", function ()
  local render = compile("<title><% return title %></title>")
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "<title>Hello, World!</title>"))
end)

test("should allow custom delimiters", function ()
  local render = compile("<title>{{ return title }}</title>", "{{", "}}")
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "<title>Hello, World!</title>"))
end)

test("should handle multiple replacements", function ()
  local render = compile("<title><% return title %> <% return title %></title>")
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "<title>Hello, World! Hello, World!</title>"))
end)

test("should handle multiple replacements", function ()
  local render = compile("<title><% return renderfile('test/res/template/title.html') %></title>") -- luacheck: ignore
  local str, deps = render({ title = "Hello, World!" })
  assert(teq(deps, { ["test/res/template/title.html"] = true }))
  assert(eq(str, "<title>Hello, World!</title>"))
end)

test("should support sharing fenv to child templates", function ()
  local render = compile("<% title = 'Hello, World!' %><title><% return renderfile('test/res/template/title.html') %></title>") -- luacheck: ignore
  local str = render({ title = "Hello, World!" })
  assert(eq(str, "<title>Hello, World!</title>"))
end)

test("should handle whitespace between blocks", function ()
  local render = compile("<title><% return renderfile('test/res/template/title.html') %> <% return renderfile('test/res/template/name.html') %></title>") -- luacheck: ignore
  local str = render({ title = "Hello, World!", name = "123" })
  assert(eq(str, "<title>Hello, World! 123</title>"))
end)

test("should support multiple nesting levels ", function ()
  local render = compile("<title><% return renderfile('test/res/template/titles.html') %></title>") -- luacheck: ignore
  local str = render({ title = "Hello, World!", name = "123" })
  assert(eq(str, "<title>Hello, World! 123</title>"))
end)

test("should support multiple templates", function ()
  local render = compile("<% a, b = compilefile('test/res/template/title.html'), compilefile('test/res/template/titles.html') %><title><% return a() %> <% return b() %></title>") -- luacheck: ignore
  local str, deps = render({ title = "Hello, World!", name = "123" })
  assert(teq(deps, {
    ["test/res/template/title.html"] = true,
    ["test/res/template/titles.html"] = true,
    ["test/res/template/name.html"] = true,
  }))
  assert(eq(str, "<title>Hello, World! Hello, World! 123</title>"))
  -- luacheck: push ignore
  -- assert(eq(serialize_deps("source.txt", "source.txt.d", deps), "source.txt: test/res/template/title.html test/res/template/titles.html test/res/template/name.html\nsource.txt.d: source.txt"))
  -- luacheck: pop
end)

test("should support multiple templates (again)", function ()
  local env = runfile("test/res/template/config.lua")
  local render = compilefile("test/res/template/index.html")
  local str = render(env)
  assert(eq(str, "Hello, World!"))
end)

test("should handle trailing characters", function ()
  local render = compile([[
    <template
      data-api="/api/ping"
      data-method="get"
      <% local iter = require("santoku.iter")
        local pairs = iter.pairs
        local map = iter.map
        local collect = iter.collect
        local concat = table.concat
        local format = string.format
        return concat(collect(map(function (status, redirect)
          return format("data-handler-%d=\"redirect:%s\"", status, redirect)
        end, pairs(redirects)))) %>>
    </template>
  ]])
  local str = render(pushindex({ redirects = { [403] = "/login" } }, _G))
  assert(eq(str, [[
    <template
      data-api="/api/ping"
      data-method="get"
      data-handler-403="redirect:/login">
    </template>]]))
end)

test("should support show/hide", function ()
  local render = compile([[
    One
    <% push(false) -- true, false %>
    Two
    <% pop() push(true) -- true, true %>
    Three
    <% push(false) -- true, true, false %>
    Four
    <% pop() -- true, true %>
    Five
    <% pop() -- true %>
    Six
    <% push(false) -- true, false %>
    Seven
    <% push(true) -- true, false, true %>
    Eight
    <% push(true) -- true, false, true, true %>
    Nine
    <% pop() -- true, false, true %>
    Ten
    <% pop() -- true, false %>
    Eleven
    <% pop() -- true %>
    Twelve
  ]])
  local str = render()
  assert(eq(str, [[
    One
    Three
    Five
    Six
    Twelve]]))
end)

test("should prepend leading characters to new lines", function ()
  local render = compile([[
    start
    #  <% return "a\nb\nc" %>
    #  <% return "%%d\n%e\n%f" %>
  ]])
  local str = render()
  assert(eq(str, [[
    start
    #  a
    #  b
    #  c
    #  %%d
    #  %e
    #  %f]]))
end)

test("file chunks share environment", function ()
  local render = compile("<% a = '1' %><% return a %>")
  assert(eq("1", render()))
end)
