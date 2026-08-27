<p align="center">
  <img src="https://santoku.dev/logo-santoku-template.png" height="64" alt="santoku-template">
</p>

# santoku-template

A Lua template engine: text with embedded `<% ... %>` Lua blocks, compiled once into a
render function you call with an environment. Blocks are plain Lua and share state within
a render, and the module also serializes Makefile-style dependency rules for build
integration.

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

A block that returns `nil` emits nothing and its surrounding blank line collapses, so
conditional sections leave no stray whitespace behind.

## Documentation

Runnable examples and the full API: [santoku.dev](https://santoku.dev/#santoku-template).

For agents and LLM tooling: [llms.txt](https://santoku.dev/llms.txt) for the index,
[llms-full.txt](https://santoku.dev/llms-full.txt) for every documented example.

## Tests

The tests are the spec. For the exhaustive surface, read them:
[`test/spec/santoku/template.lua`](test/spec/santoku/template.lua) and
[`test/spec/santoku/template_deps.lua`](test/spec/santoku/template_deps.lua).

## License

MIT, see [LICENSE](LICENSE).

## More examples

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
