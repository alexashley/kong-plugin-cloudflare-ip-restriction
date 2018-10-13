local _Module = {}

-- https://github.com/openresty/lua-nginx-module#data-sharing-within-an-nginx-worker
-- It's not recommended to share writeable data this way, but the result of a CIDR or binary ip computation should never change
-- so there should be few conflicting writes.
local computed_bin_ip = {}

function _Module.get_bin_ip(ip)
    return computed_bin_ip[ip]
end

function _Module.set_bin_ip(ip_string, bin_ip)
    if (computed_bin_ip[ip_string]) then
        return
    end

    computed_bin_ip[ip_string] = bin_ip
end

return _Module