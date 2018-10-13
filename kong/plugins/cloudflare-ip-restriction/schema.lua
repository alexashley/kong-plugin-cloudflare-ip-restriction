return {
    no_consumer = true,
    fields = {
        whitelist = {
            type = "array",
            func = function(whitelist)
                -- [
                --  {
                --     "ip": "1.2.3.4",
                --     "description": "Corporate LAN"
                --  }
                -- ]
                return true
            end
        },
        override_global_whitelist = {
            type = "boolean",
            default = false
        },
        client_ip_headers = {
            type = "array",
            required = true,
            default = {"CF-Connecting-IP"}
        }
    },
}
