local host = "us-east-1.production.includedhealth.com"
local env = vim.env

return {
  loki = env.GTUI_LOKI or ("https://grafana-loki." .. host),
  mimir = env.GTUI_MIMIR or ("https://grafana-mimir." .. host .. "/prometheus"),
  tempo = env.GTUI_TEMPO or ("https://grafana-tempo." .. host),
  loki_tenant = env.GTUI_LOKI_TENANT or "tenant-general",
  grafana = env.GRAFANA_URL or "https://grafana.includedhealth.com",
  grafana_token = env.GRAFANA_API_KEY,

  envs = { "production", "uat", "integration3" },
  env_vars = { "environment", "env", "tng_environment" },
  ranges = {
    { "5m", 300 }, { "15m", 900 }, { "1h", 3600 },
    { "6h", 21600 }, { "24h", 86400 }, { "7d", 604800 },
  },
  default_range = 3,
}
