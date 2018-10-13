provider "kong" {
  admin_api_url = "http://localhost:8001"
}

resource "kong_service" "mockbin" {
  name = "mockbin"
  url = "https://mockbin.org/request"
}

resource "kong_route" "mock" {
  service_id = "${kong_service.mockbin.id}"
  paths = ["/ip"]
}

resource "kong_plugin" "cloudflare-ip-restriction" {
  name = "cloudflare-ip-restriction"
  route_id = "${kong_route.mock.id}"
  config_json =<<CONFIG
{
  "whitelist": [
    {
      "ip": "8.8.8.8",
      "description": "GCP traffic"
    },
    {
      "ip": "1.2.3.4",
      "description": "Corporate LAN"
    }
  ]
}
CONFIG
}

// global plugin
resource "kong_plugin" "cloudflare-ip-restriction-worldwide" {
  name = "cloudflare-ip-restriction"
  config_json =<<CONFIG
{
  "whitelist": [
    {
      "ip": "5.5.5.5",
      "description": "Data center"
    }
  ]
}
CONFIG
}