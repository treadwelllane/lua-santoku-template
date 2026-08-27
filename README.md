<p align="center">
  <img src="https://santoku.dev/logo.png" width="96" alt="santoku logo">
</p>

# santoku-template

A Lua template engine: text with embedded `<% ... %>` Lua blocks, compiled once
into a render function you call with an environment. Blocks are plain Lua and
share state within a render, and the module also serializes Makefile-style
dependency rules for build integration.

## Install

```sh
luarocks install santoku-template
```

## Example

```lua
local template = require("santoku.template")

local render = template.compile("<title><% return title %></title>")
print(render({ title = "Hello, World!" }))
```

## Documentation

Full documentation with runnable examples:
[santoku.dev](https://santoku.dev/#santoku-template).

## Tests

For thorough examples of every behavior, read the specs in
[test/spec/santoku](test/spec/santoku). The tests are the reference.

## License

MIT, see [LICENSE](LICENSE).

## Anchor spec

The spec below is `test/spec/santoku/template_anchor.lua`, reproduced verbatim.
It runs and passes as part of the test suite, and a companion spec
(`test/spec/santoku/template_readme.lua`) fails the suite if this README and
that file ever differ.

```lua
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
```
