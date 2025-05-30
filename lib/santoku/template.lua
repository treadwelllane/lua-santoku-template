local err = require("santoku.error")
local error = err.error
local assert = err.assert

local lua = require("santoku.lua")
local loadstring = lua.loadstring
local setfenv = lua.setfenv

local validate = require("santoku.validate")
local hascall = validate.hascall
local hasindex = validate.hasindex
local isstring = validate.isstring

local tbl = require("santoku.table")
local inherit = require("santoku.inherit")

local fs = require("santoku.fs")
local readfile = fs.readfile
local files = fs.files
local extensions = fs.extensions
local basename = fs.basename
local stripextensions = fs.stripextensions

local iter = require("santoku.iter")
local interleave = iter.interleave
local keys = iter.keys
local collect = iter.collect

local str = require("santoku.string")
local sescape = str.escape

local arr = require("santoku.array")
local extend = arr.extend
local push = arr.push
local concat = arr.concat
local copy = arr.copy

local sfind = string.find
local gsub = string.gsub
local ssub = string.sub

local def_open = "<%%"
local def_close = "%%>"

local compile
local compilefile

local function compiledir (dir, open, close, deps, showstack, parent_env)
  dir = hascall(dir) and dir or files(dir)
  local ret = {}
  for file in dir do
    local template = compilefile(file, open, close, deps, showstack, parent_env)
    local exts = gsub(extensions(file), "^%.", "")
    local name = stripextensions(basename(file))
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
        showstack[#showstack + 1] =  not not tf -- not not converts to boolean
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
        return compile(readfile(fp), open1 or open0, close1 or close0, deps, showstack, env)(env1, global1 or global)
      end,

      readfile = function (fp)
        deps[fp] = true
        return readfile(fp)
      end,

    }

    tbl.merge(env, render_env or {}, base_env or {}, parent_env or {})
    inherit.pushindex(env, global)

    local parts = copy({}, parts)
    local showing = base_env.showing

    for i = 1, #parts do

      local d = parts[i]
      local fn, prefix_flag

      if hascall(d) then
        fn = true
        d, prefix_flag = setfenv(d, env)()
      else
        fn = false
      end

      if d ~= nil then
        assert(isstring(d))
        if showing() then
          local shown = output[#output]
          output[#output + 1] = d
          if shown and fn and prefix_flag ~= false then
            local ps, pe = sfind(shown, "\n[^\n]*$")
            if ps then
              local prefix = sescape(ssub(shown, ps, pe))
              output[#output] = gsub(output[#output], "\n%s*", prefix)
            end
          end
        end
      else
        skipped[#skipped + 1] = #output
      end

    end

    if #output > 1 then
      output[#output] = gsub(output[#output], "\n%s*$", "")
    end

    for i = 1, #skipped do
      local oi = skipped[i]
      if output[oi] and output[oi + 1] then
        local ls = sfind(output[oi], "\n%s*$")
        local rs, re = sfind(output[oi + 1], "^%s*\n")
        if ls and rs then
          output[oi] = ssub(output[oi], 1, ls - 1)
          output[oi + 1] = ssub(output[oi + 1], re)
        end
      end
    end

    return concat(output), deps

  end
end

compile = function (data, open, close, deps, showstack, parent_env)

  local open = open or def_open
  local close = close or def_close

  local parts = {}
  local pos = 1
  local ss, se, es, ee

  while true do
    ss, se = sfind(data, open, pos)
    if not ss then
      local after = ssub(data, pos)
      if #after > 0 then
        parts[#parts + 1] = after
      end
      break
    else
      es, ee = sfind(data, close, se + 1)
      if not es then
        error("Invalid template: unexpected character", ss)
      else
        local before = ssub(data, pos, ss - 1)
        if #before > 0 then
          parts[#parts + 1] = before
        end
        local code = ssub(data, se + 1, es - 1)
        parts[#parts + 1] = loadstring(code, nil)
        pos = ee + 1
      end
    end
  end

  return renderer(parts, open, close, deps, showstack, parent_env)

end

compilefile = function (fp, open, close, deps, showstack, parent_env)
  return compile(readfile(fp), open, close, deps, showstack, parent_env)
end

local function render (data, env, global, open, close, deps, showstack, parent_env)
  return compile(data, open, close, deps, showstack, parent_env)(env, global)
end

local function renderfile (fp, env, global, open, close, deps, showstack, parent_env)
  return compilefile(fp, open, close, deps, showstack, parent_env)(env, global)
end

local function serialize_deps (source, dest, deps)
  assert(isstring(source))
  assert(isstring(dest))
  assert(hasindex(deps))
  local out = {}
  push(out, source, ": ")
  extend(out, collect(interleave(" ", keys(deps))))
  push(out, "\n", dest, ": ", source)
  return concat(out)
end

return {
  compile = compile,
  compilefile = compilefile,
  render = render,
  renderfile = renderfile,
  serialize_deps = serialize_deps
}
