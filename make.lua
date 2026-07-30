local env = {
  name = "santoku-template",
  version = "1.0.0-1",
  variable_prefix = "TK_TEMPLATE",
  license = "MIT",
  public = true,
  dependencies = {
    "lua == 5.1",
    "santoku-lpeg >= 1.0.0, < 2.0.0",
    "santoku >= 1.0.0, < 2.0.0",
    "santoku-fs >= 1.0.0, < 2.0.0"
  },
}

env.homepage = "https://github.com/birchpointswe/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
}
