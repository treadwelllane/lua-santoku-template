local test = require("santoku.test")

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal

local template = require("santoku.template")

test("interpolate values into a template", function ()
  local render = template.compile("<title><% return title %></title>")
  assert(eq(render({ title = "Hello, World!" }), "<title>Hello, World!</title>"))
end)

test("blocks share one environment per render", function ()
  local out = template.render("<% greeting = 'hi' %><% return greeting .. ', ' .. name %>", { name = "ada" })
  assert(eq(out, "hi, ada"))
end)

test("compile once, render many", function ()
  local render = template.compile("<% return name %>!")
  assert(eq(render({ name = "ada" }), "ada!"))
  assert(eq(render({ name = "alan" }), "alan!"))
end)

test("serialize a makefile-style dependency rule", function ()
  local rule = template.serialize_deps("page.html", "page.out", { ["header.html"] = true })
  assert(eq(rule, "page.html: header.html\npage.out: page.html"))
end)
