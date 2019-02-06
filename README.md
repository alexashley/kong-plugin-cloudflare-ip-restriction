# kong-plugin-cloudflare-ip-restriction

A plugin for human-friendly IP whitelisting for Kong installs behind Cloudflare (or another trusted proxy).

# WARNING

I have **not** used this in a production environment. I mostly wrote the plugin to play around with Kong's PDK.
I would recommend using Cloudflare's [lockdown rules](https://support.cloudflare.com/hc/en-us/articles/115001595131-How-do-I-Lockdown-URLs-in-Cloudflare-) and then using Kong's own ip restriction plugin to only allow traffic from Cloudflare

## comparision to `ip-restriction` plugin

Kong's built-in `ip-restriction` plugin uses `ngx.var.binary_remote_addr` to apply IP restrictions; 
however, if your Kong installation is behind Cloudflare, the IP will be Cloudflare's proxy IP, not the client's IP address.

Fixing that requires an [nginx config change](https://docs.konghq.com/0.14.x/configuration/#real_ip_header) and a redeployment of Kong. 
Instead, this plugin supports reading IP addresses from multiple headers to determine if an IP is allowed access. 
It allows for dynamic changes without the need to re-deploy Kong or touch NGINX config; for example, this might be useful while migrating between WAFs.  

Other features:
    
- Installing the plugin globally will provide IP whitelisting for all services/routes, with individual plugin installs extending the global plugin's whitelist by default. 
- The whitelist configuration allows for a description of the IP address. 

## security concerns

This plugin assumes that Kong is only reachable via a trusted proxy. Spoofing a header is trivial and this plugin provides no additional safety mechanisms.

## install

`export KONG_CUSTOM_PLUGINS=cloudflare-ip-restriction`

## configuration


| name                        | description                                                                                              | default                |
|-----------------------------|----------------------------------------------------------------------------------------------------------|------------------------|
| `whitelist`                 | Array of objects of the form `{"ip": "cidr-or-ip-address", "description": "a useful note about the ip"}` | N/A                    |
| `override_global_whitelist` | Don't use the global plugin's whitelist when determining if the IP is allowed.                           | false                  |
| `client_ip_headers`         | An array of headers to check for IP addresses.                                                           | `{"CF-Connecting-IP"}` |


By default, the plugin is configured to be used with Cloudflare; if you're a Cloudfare enterprise customer, you may wish to change the default `client_ip_headers` to include [`True-Client-IP`](https://support.cloudflare.com/hc/en-us/articles/206776727-What-is-True-Client-IP-).

Sample installation:

```shell

CONFIG=$(cat <<-END
    {
        "name": "cloudflare-ip-restriction",
        "config": {
            "whitelist": [{
                "ip": "5.5.5.5",
                "description": "Corporate LAN"
            }]
        }
    }
END
)

curl -s ${KONG_ADMIN_API}/plugins -H "Content-Type: application/json" -d ${CONFIG}
```

## development

- Use`docker-compose up` to start Kong 0.14.1 & Postgres.
- A simple Terraform config is included for the sake of manual testing. It requires [`terraform-provider-kong`](https://github.com/alexashley/terraform-provider-kong). 
