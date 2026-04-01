local err = require("santoku.error")
local lua = require("santoku.lua")
local lpeg = require("lpeg")
local vdt = require("santoku.validate")
local tbl = require("santoku.table")
local inherit = require("santoku.inherit")
local fs = require("santoku.fs")
local str = require("santoku.string")
local arr = require("santoku.array")

local P, C, Ct, Cp = lpeg.P, lpeg.C, lpeg.Ct, lpeg.Cp

local grammar = (function ()
  local open = P("<%")
  local close = P("%>")
  local code = open * Cp() * C((1 - close)^0) * close / function (pos, code)
    local fn, e = lua.loadstring(code, nil)
    if not fn then
      err.error("Invalid Lua code in template at position " .. pos .. ": " .. (e or "syntax error"))
    end
    return fn
  end
  return Ct((code + C((1 - open)^1))^0)
end)()

local function compile (data)
  local parts = grammar:match(data)
  if not parts then
    err.error("Failed to parse template")
  end
  return function (render_env, global)
    local env = {}
    tbl.merge(env, render_env or {})
    inherit.pushindex(env, global)
    local output = {}
    local skipped = {}
    for i = 1, #parts do
      local d = parts[i]
      if vdt.hascall(d) then
        local prev = output[#output]
        env._prefix = prev and str.match(prev, "\n([ \t]*)$") or ""
        d = lua.setfenv(d, env)()
      end
      if d ~= nil then
        err.assert(vdt.isstring(d))
        output[#output + 1] = d
      else
        skipped[#skipped + 1] = #output
      end
    end
    if #output > 1 then
      output[#output] = str.gsub(output[#output], "\n%s*$", "")
    end
    for i = 1, #skipped do
      local oi = skipped[i]
      if output[oi] and output[oi + 1] then
        local ls = str.find(output[oi], "\n%s*$")
        local rs, re = str.find(output[oi + 1], "^%s*\n")
        if ls and rs then
          output[oi] = str.sub(output[oi], 1, ls - 1)
          output[oi + 1] = str.sub(output[oi + 1], re)
        end
      end
    end
    return arr.concat(output)
  end
end

local function compilefile (fp)
  return compile(fs.readfile(fp))
end

local function render (data, env, global)
  return compile(data)(env, global)
end

local function renderfile (fp, env, global)
  return compilefile(fp)(env, global)
end

local function serialize_deps (source, dest, deps)
  err.assert(vdt.isstring(source))
  err.assert(vdt.isstring(dest))
  err.assert(vdt.hasindex(deps))
  local out = {}
  arr.push(out, source, ": ")
  arr.push(out, arr.spread(arr.interleaved(tbl.keys(deps), " ")))
  arr.push(out, "\n", dest, ": ", source)
  return arr.concat(out)
end

local function deserialize_deps (data)
  err.assert(vdt.isstring(data))
  local deps = {}
  local first_line = str.match(data, "^[^\n]+")
  if first_line then
    local after_colon = str.match(first_line, ":%s*(.*)$")
    if after_colon then
      for dep in str.gmatch(after_colon, "%S+") do
        deps[dep] = true
      end
    end
  end
  return deps
end

return {
  compile = compile,
  compilefile = compilefile,
  render = render,
  renderfile = renderfile,
  serialize_deps = serialize_deps,
  deserialize_deps = deserialize_deps
}
