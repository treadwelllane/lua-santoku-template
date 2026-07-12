local env = {
  name = "santoku-template",
  version = "0.0.39-1",
  variable_prefix = "TK_TEMPLATE",
  license = "MIT",
  public = true,
  dependencies = {
    "lua == 5.1",
    "santoku-lpeg >= 0.0.7-1",
    "santoku >= 0.0.328-1",
    "santoku-fs >= 0.0.45-1"
  },
}

env.homepage = "https://github.com/birchpointswe/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
}
