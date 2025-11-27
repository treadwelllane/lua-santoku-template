local err = require("santoku.error")
local lua = require("santoku.lua")
local lpeg = require("lpeg")
local vdt = require("santoku.validate")
local tbl = require("santoku.table")
local inherit = require("santoku.inherit")
local fs = require("santoku.fs")
local iter = require("santoku.iter")
local str = require("santoku.string")
local arr = require("santoku.array")

local P, C, Ct, Cp = lpeg.P, lpeg.C, lpeg.Ct, lpeg.Cp

local def_open = "<%"
local def_close = "%>"

local function build_template_grammar(open, close)
  local open_p = P(open)
  local close_p = P(close)
  local code_content = Cp() * C((1 - close_p)^0)
  local code_block = open_p * code_content * close_p / function(pos, code)
    local fn, err_msg = lua.loadstring(code, nil)
    if not fn then
      err.error("Invalid Lua code in template at position " .. pos .. ": " .. (err_msg or "syntax error"))
    end
    return fn
  end
  local text_content = C((1 - open_p)^1)
  return Ct((code_block + text_content)^0)
end

local default_grammar = build_template_grammar(def_open, def_close)

local compile
local compilefile

local function compiledir (dir, open, close, deps, showstack, parent_env)
  dir = vdt.hascall(dir) and dir or fs.files(dir)
  local ret = {}
  for file in dir do
    local template = compilefile(file, open, close, deps, showstack, parent_env)
    local exts = str.gsub(fs.extensions(file), "^%.", "")
    local name = fs.stripextensions(fs.basename(file))
    ret[exts] = ret[exts] or {}
    ret[exts][name] = template
  end
  return ret
end

local function renderer (parts, open0, close0, deps, showstack, parent_env)
  return function (render_env, global)

    local deps = deps or {}
    local showstack = showstack or { true }
    local output = {}
    local skipped = {}

    local env = {}

    local base_env = {
      push = function (tf)
        showstack[#showstack + 1] =  not not tf
      end,
      pop = function ()
        showstack[#showstack] = nil
      end,
      showing = function ()
        for i = #showstack, 1, -1 do
          if showstack[i] == false then
            return false
          end
        end
        return true
      end,
      compile = function (data, open1, close1)
        return compile(data, open1 or open0, close1 or close0, deps, showstack, env)
      end,
      compilefile = function (fp, open1, close1)
        deps[fp] = true
        return compilefile(fp, open1 or open0, close1 or close0, deps, showstack, env)
      end,
      compiledir = function (dir, open1, close1)
        return compiledir(dir, open1 or open0, close1 or close0, deps, showstack, env)
      end,
      renderfile = function (fp, env1, global1, open1, close1)
        deps[fp] = true
        return compile(fs.readfile(fp), open1 or open0, close1 or close0, deps, showstack, env)(env1, global1 or global)
      end,
      readfile = function (fp)
        deps[fp] = true
        return fs.readfile(fp)
      end,
    }

    tbl.merge(env, render_env or {}, base_env or {}, parent_env or {})
    inherit.pushindex(env, global)

    local parts = arr.copy({}, parts)
    local showing = base_env.showing

    for i = 1, #parts do

      local d = parts[i]
      local fn, prefix_flag

      if vdt.hascall(d) then
        fn = true
        d, prefix_flag = lua.setfenv(d, env)()
      else
        fn = false
      end

      if d ~= nil then
        err.assert(vdt.isstring(d))
        if showing() then
          local shown = output[#output]
          output[#output + 1] = d
          if shown and fn and prefix_flag ~= false then
            local ps, pe = str.find(shown, "\n[^\n]*$")
            if ps then
              local prefix = str.escape(str.sub(shown, ps, pe))
              output[#output] = str.gsub(output[#output], "\n%s*", prefix)
            end
          end
        end
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

    return arr.concat(output), deps

  end
end

compile = function (data, open, close, deps, showstack, parent_env)
  local open = open or def_open
  local close = close or def_close
  local grammar
  if open == def_open and close == def_close then
    grammar = default_grammar
  else
    grammar = build_template_grammar(open, close)
  end
  local parts = grammar:match(data)
  if not parts then
    err.error("Failed to parse template: unmatched delimiters or invalid syntax")
  end
  return renderer(parts, open, close, deps, showstack, parent_env)
end

compilefile = function (fp, open, close, deps, showstack, parent_env)
  return compile(fs.readfile(fp), open, close, deps, showstack, parent_env)
end

local function render (data, env, global, open, close, deps, showstack, parent_env)
  return compile(data, open, close, deps, showstack, parent_env)(env, global)
end

local function renderfile (fp, env, global, open, close, deps, showstack, parent_env)
  return compilefile(fp, open, close, deps, showstack, parent_env)(env, global)
end

local function serialize_deps (source, dest, deps)
  err.assert(vdt.isstring(source))
  err.assert(vdt.isstring(dest))
  err.assert(vdt.hasindex(deps))
  local out = {}
  arr.push(out, source, ": ")
  arr.extend(out, iter.collect(iter.interleave(" ", iter.keys(deps))))
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
