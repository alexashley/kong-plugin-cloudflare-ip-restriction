local ip_utils = require("resty.iputils")
local ip_cache = require("kong.plugins.cloudflare-ip-restriction.cache")

local cloudflare_ip_restriction_plugin = require("kong.plugins.base_plugin"):extend()

function cloudflare_ip_restriction_plugin:new()
    cloudflare_ip_restriction_plugin.super.new(self, "cloudflare-ip-restriction")
end

local function to_binary_string(octets)
    local bin = ""
    for _, octet in ipairs(octets) do
        bin = bin .. string.char(octet)
    end

    return bin
end

local function get_binary_ip(ip)
    local cached = ip_cache.get_bin_ip(ip)

    if cached then
        return cached
    end

    local parsed_ip, octets_or_err = ip_utils.ip2bin(ip)

    -- failed to parse the IP address
    if not parsed_ip and octets_or_err then
        return nil, octets_or_err
    end

    local binary_ip = to_binary_string(octets_or_err)

    ip_cache.set_bin_ip(ip, binary_ip)

    return binary_ip
end

local function get_global_plugin_whitelist()
    local conf = kong.ctx.plugin.conf.whitelist

    if conf.override_global_whitelist then
        return nil
    end

    local all_plugins, err = kong.dao.plugins:find_all({ name = "cloudflare-ip-restriction" })

    if err then
        kong.log.err(err)
        return nil
    end

    local global_plugin

    for _, plugin in ipairs(all_plugins) do
        local is_global = not (plugin.api_id or plugin.service_id or plugin.route_id)

        if is_global then
            global_plugin = plugin
            break
        end
    end

    if not global_plugin then
        return nil
    end

    return global_plugin.config.whitelist
end

local function get_cidr_whitelist()
    local whitelist_mapping = kong.ctx.plugin.conf.whitelist
    local whitelist_ips = {}

    for _, ip_config in pairs(whitelist_mapping) do
        whitelist_ips[#whitelist_ips+1] = ip_config.ip
    end

    local global_plugin_whitelist = get_global_plugin_whitelist()

    if global_plugin_whitelist then
        for _, ip_config in pairs(global_plugin_whitelist) do
            whitelist_ips[#whitelist_ips+1] = ip_config.ip
        end
    end

    return ip_utils.parse_cidrs(whitelist_ips)
end

local function in_whitelist(ip)
    local whitelist = get_cidr_whitelist()

    local binary_ip, err = get_binary_ip(ip)

    if err then
        kong.log.debug("error parsing ip address", err)
        return false
    end

    local in_range = ip_utils.binip_in_cidrs(binary_ip, whitelist)

    return in_range
end

local function validate_client_ip()
    local conf = kong.ctx.plugin.conf

    local match = false
    for _, header in ipairs(conf.client_ip_headers) do
        local header_value = kong.request.get_header(header)

        if header_value and in_whitelist(header_value) then
            match = true
            break
        end
    end

    return match
end

function cloudflare_ip_restriction_plugin:access(conf)
    cloudflare_ip_restriction_plugin.super.access(self)
    kong.ctx.plugin.conf = conf

    local ok = validate_client_ip()

    if not ok then
        return kong.response.exit(401, "IP not allowed")
    end
end

cloudflare_ip_restriction_plugin.PRIORITY = 1000

return cloudflare_ip_restriction_plugin
