local env = {
  name = "santoku-template",
  version = "0.0.32-1",
  variable_prefix = "TK_TEMPLATE",
  license = "MIT",
  public = true,
  dependencies = {
    "lua >= 5.1",
    "lpeg >= 1.1.0-2",
    "santoku >= 0.0.303-1",
    "santoku-fs >= 0.0.37-1"
  },
}

env.homepage = "https://github.com/treadwelllane/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return {
  env = env,
}
