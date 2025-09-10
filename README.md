# lua-santoku-template

Lua template engine for text generation and file processing.

## API Reference

### Core Functions

| Function | Arguments | Returns | Description |
|----------|-----------|---------|-------------|
| `compile` | `data, [open], [close], [deps], [showstack], [parent_env]` | `function` | Compiles template string to render function |
| `compilefile` | `filepath, [open], [close], [deps], [showstack], [parent_env]` | `function` | Compiles template file to render function |
| `render` | `data, env, [global], [open], [close], [deps], [showstack], [parent_env]` | `string, deps` | Renders template string directly |
| `renderfile` | `filepath, env, [global], [open], [close], [deps], [showstack], [parent_env]` | `string, deps` | Renders template file directly |
| `serialize_deps` | `source, dest, deps` | `string` | Serializes dependencies in Makefile format |

#### Arguments

- `data` - Template string to compile/render
- `filepath` - Path to template file
- `env` - Environment table with template variables
- `global` - Global environment table (defaults to `_G`)
- `open`, `close` - Custom delimiters (defaults to `<%`, `%>`)
- `deps` - Dependency tracking table
- `showstack` - Stack for conditional rendering
- `parent_env` - Parent template environment

#### Returns

- Compiled functions return a render function that takes `(env, [global])` and returns `string, deps`
- Render functions return the rendered string and dependency table

### Template Environment Functions

These functions are available within templates:

| Function | Arguments | Description |
|----------|-----------|-------------|
| `push` | `condition` | Pushes a show/hide condition onto the stack |
| `pop` | `()` | Pops the top condition from the stack |
| `showing` | `()` | Returns true if content should be shown |
| `compile` | `data, [open], [close]` | Compiles a template string in current context |
| `compilefile` | `filepath, [open], [close]` | Compiles a template file in current context |
| `renderfile` | `filepath, [env], [global], [open], [close]` | Renders a template file in current context |
| `readfile` | `filepath` | Reads a file (with dependency tracking) |

## Template Syntax

Templates embed Lua code using delimiters (default `<%` and `%>`):

### Basic Syntax

```html
<!-- Output a value -->
<title><% return title %></title>

<!-- Execute code -->
<% local x = 10 %>

<!-- Multiple statements -->
<%
  local fs = require("santoku.fs")
  local content = fs.readfile("data.txt")
%>

<!-- Output result -->
<% return content %>
```

### Nested Templates

Templates can include other templates using `renderfile()`:

```html
<html>
  <head><% return renderfile("header.html") %></head>
  <body><% return renderfile("content.html") %></body>
</html>
```

The parent template's environment is shared with nested templates:

```html
<!-- main.html -->
<% title = "My Page" %>
<% return renderfile("header.html") %>

<!-- header.html -->
<title><% return title %></title>
```

### Conditional Rendering

Use `push()`, `pop()`, and `showing()` for conditional content:

```html
<% push(show_debug) %>
  Debug info: <% return debug_message %>
<% pop() %>

<% push(user and user.admin) %>
  Admin panel link
  <% push(user.super_admin) %>
    Super admin controls
  <% pop() %>
<% pop() %>
```

The `showing()` function checks if content should be rendered:

```html
<% push(condition) %>
  <% if showing() then
    return "This is shown when condition is true"
  end %>
<% pop() %>
```

### Automatic Indentation

Multi-line output preserves the indentation of the template location:

```html
<div>
  <% return "line1\nline2\nline3" %>
</div>
```

Results in:
```html
<div>
  line1
  line2
  line3
</div>
```

### Dependency Tracking

Templates automatically track file dependencies when using `readfile()` or `renderfile()`:

```lua
local result, deps = template.renderfile("main.html", { title = "Test" })
-- deps = { ["header.html"] = true, ["content.html"] = true }

-- Serialize for Makefiles
print(template.serialize_deps("main.html", "output.html", deps))
-- Output: main.html: header.html content.html
--         output.html: main.html
```

## Related Modules

- [lua-santoku-make](https://github.com/treadwelllane/lua-santoku-make) - Build system using this template engine
- [lua-santoku-cli](https://github.com/treadwelllane/lua-santoku-cli) - Command line tools for template processing

## License

MIT License

Copyright 2025 Matthew Brooks

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
