local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local validate = require("santoku.validate")
local eq = validate.isequal

local tbl = require("santoku.table")
local teq = tbl.equals

local template = require("santoku.template")
local compile = template.compile

local fs = require("santoku.fs")

test("renderfile include chain wired through a shared env", function ()


  local env
  local function renderfile (fp)
    return compile(fs.readfile(fp))(env, _G)
  end
  env = { renderfile = renderfile, title = "Hello, World!" }
  local render = compile("<% return renderfile('test/res/template/index.html') %>")
  local str = render(env)
  assert(eq(str, "Hello, World!"))
end)

test("serialize_deps emits makefile rule", function ()
  local deps = { ["a.html"] = true }
  local out = template.serialize_deps("main.html", "out.html", deps)
  assert(eq(out, "main.html: a.html\nout.html: main.html"))
end)

test("deserialize_deps round-trips the dep set", function ()
  local deps = { ["a.html"] = true, ["b.html"] = true }
  local data = template.serialize_deps("main.html", "out.html", deps)
  local got = template.deserialize_deps(data)
  assert(teq(got, deps))
end)
