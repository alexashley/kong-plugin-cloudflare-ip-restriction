package = "kong-plugin-cloudflare-ip-restriction"
version = "0.1.0-1"

supported_platforms = {"linux", "macosx"}
source = {
  url = "git@github.com:alexashley/kong-plugin-ip-whitelist.git",
}

description = {
  summary = "A plugin that enables human-friendly ip whitelisting",
  license = "MIT"
}

dependencies = {}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.cloudflare-ip-restriction.handler"] = "kong/plugins/cloudflare-ip-restriction/handler.lua",
    ["kong.plugins.cloudflare-ip-restriction.schema"] = "kong/plugins/cloudflare-ip-restriction/schema.lua",
    ["kong.plugins.cloudflare-ip-restriction.cache"] = "kong/plugins/cloudflare-ip-restriction/cache.lua",
  }
}
