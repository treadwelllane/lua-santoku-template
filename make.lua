local env = {

  name = "santoku-template",
  version = "0.0.14-1",
  variable_prefix = "TK_TEMPLATE",
  license = "MIT",
  public = true,

  dependencies = {
    "lua >= 5.1",
    "santoku >= 0.0.177-1",
    "santoku-fs >= 0.0.19-1"
  },

  test = {
    dependencies = {
      "luacov >= 0.15.0-1",
    }
  },

}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  type = "lib",
  env = env,
  rules = {
    copy = {
      "lib/santoku/template.lua",
      "test/spec/santoku/template.lua",
      "test/spec/santoku/cli/template.lua"
    }
  }
}
