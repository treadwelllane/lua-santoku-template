# santoku-template

A Lua template engine: text with embedded `<% ... %>` Lua blocks compiled to a
render function. Built on base `santoku` (errors, validation, string, table,
array, inherit), `santoku-fs` for file reading, and `lpeg` for the parser. See
[../lua-santoku/README.md](../lua-santoku/README.md) and
[../lua-santoku-fs/README.md](../lua-santoku-fs/README.md) for those surfaces, and
the [lpeg manual](http://www.inf.puc-rio.br/~roberto/lpeg/) for the grammar layer.

This README is a usage guide, not an API reference. The tests are the spec:
`test/spec/santoku/template.lua` exercises the core surface and
`test/spec/santoku/template_deps.lua` covers includes and dependency
serialization. Read those for the exhaustive behavior; read this for how the
pieces fit.

## Model

A template is text interleaved with `<% ... %>` blocks. Each block is Lua source,
compiled with `santoku.lua.loadstring` at compile time (a syntax error in a block
raises with the block's position). Text outside the blocks is emitted verbatim.

`compile(data)` parses once and returns `render(env, global)`. Calling the render
function runs each block with its own environment: a fresh table seeded from
`env`, with `global` (often `_G`) on its `__index` chain via `santoku.inherit`. A
block that `return`s a string contributes that string to the output; a block that
returns nothing (statements only) contributes nothing but its side effects on the
shared environment persist to later blocks in the same render.

```lua
local template = require("santoku.template")

local render = template.compile("<title><% return title %></title>")
render({ title = "Hello, World!" })        -- "<title>Hello, World!</title>"

-- statements run for effect; state carries to later blocks in the same render
template.render("<% a = '1' %><% return a %>")   -- "1"
```

`render(data, env, global)` and `renderfile(fp, env, global)` are compile-then-call
shortcuts. `compilefile(fp)` reads the file through `santoku.fs.readfile` and
compiles its contents.

## In-block environment

Each block runs with these names available beyond `env`/`global`:

- `_prefix`: the whitespace indentation of the current block's line, captured from
  the text immediately before it. Use it to re-indent multi-line output so nested
  lines line up with the block.
- `push(cond)` / `pop()` / `showing()`: a conditional-output stack. `push` ANDs
  `cond` with the current state and pushes it; while the top is false, returned
  strings are dropped; `pop` restores the previous state. `showing()` reads the
  current state. Nested `push`/`pop` pairs compose.

```lua
-- _prefix re-indents a returned multi-line string to the block's column
local str = require("santoku.string")
template.compile("start\n  <% return str.gsub('a\\nb\\nc', '\\n', '\\n' .. _prefix) %>")
  ({ str = str })                          -- "start\n  a\n  b\n  c"

-- push/pop gate a region
template.compile("<% push(cond) %><% return 'x' %><% pop() %>")({ cond = false })  -- ""
```

Covers: variable interpolation, multiple blocks, shared block state, repeated
rendering of one compiled template, and the `_prefix` cases in
`test/spec/santoku/template.lua`.

## Whitespace collapsing

A block that returns nothing collapses the blank line around it: when an empty
block sits on its own line, the trailing newline of the preceding text and the
leading newline of the following text are joined, so removed blocks do not leave
gaps. Trailing whitespace on the final output chunk is trimmed.

```lua
template.compile("one\n<% %>\ntwo")()      -- "one\ntwo"
```

Covers: `nil blocks collapse surrounding blank lines` in the core test.

## Includes

This engine does not inject an include function into the block environment. To
nest templates, pass a helper (a `readfile` or a `renderfile`) through `env` or
`global`; the block then calls it like any other value. This keeps file access
explicit and the engine free of a fixed filesystem policy.

```lua
local fs = require("santoku.fs")

-- raw file include via readfile passed in env
template.compile("<% return readfile('test/res/template/title.html') %>")
  ({ readfile = fs.readfile })

-- nested render: the caller's renderfile threads the SAME env down each level,
-- so a multi-level include chain (index -> body -> body-content) keeps seeing
-- both renderfile and the data (here, title).
local env
local function renderfile (fp)
  return template.compile(fs.readfile(fp))(env, _G)
end
env = { renderfile = renderfile, title = "Hello, World!" }
template.compile("<% return renderfile('test/res/template/index.html') %>")(env)
-- "Hello, World!"
```

Covers: `readfile provided via env` in the core test and the `renderfile include
chain wired through a shared env` case in `template_deps.lua`. The fixtures under
`test/res/template/` (`index.html`, `body.html`, `body-content.html`, ...) chain
through this pattern; pass a `renderfile` that re-threads the shared env.

## Dependency serialization

When a build threads file accesses through the env, the caller can record which
files a template read and emit a Makefile-style rule. `serialize_deps(source,
dest, deps)` writes the rule; `deserialize_deps(data)` parses the dependency set
back out of the first line.

```lua
local deps = { ["a.html"] = true }
template.serialize_deps("main.html", "out.html", deps)
-- "main.html: a.html\nout.html: main.html"

template.deserialize_deps("main.html: a.html b.html")   -- { ["a.html"] = true, ["b.html"] = true }
```

Covers: `serialize_deps emits makefile rule` and `deserialize_deps round-trips the
dep set` in `template_deps.lua`. The `deps` table itself is built by the caller;
this module only serializes and parses it.

## Building / testing

This repo uses the `toku` build harness. Specs live in `test/spec/santoku/`. Run
the suite through `toku` so `lpeg` and the `santoku` dependencies are on the path.
Spec file edits need a forced rebuild/reinstall before a run.

## License

MIT License

Copyright 2025 Birch Point SWE

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
