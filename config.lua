local env = {

  name = "santoku-template",
  version = "0.0.8-1",
  variable_prefix = "TK_TEMPLATE",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
    "santoku >= 0.0.157-1",
    "santoku-fs >= 0.0.11-1"
  },

  test_dependencies = {
    "santoku-test >= 0.0.6-1",
    "luassert >= 1.9.0-1",
    "luacov >= 0.15.0-1",
    "inspect >= 3.1.3-0"
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
  excludes = {
    "lib/santoku/template.lua",
    "test/spec/santoku/template.lua",
    "test/spec/santoku/cli/template.lua"
  },
}
