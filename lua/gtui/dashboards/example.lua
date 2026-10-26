return {
  title = "Example",
  vars = { window = "5m" },
  panels = {
    {
      title = "Request rate by namespace",
      type = "timeseries",
      span = 2,
      ds = "mimir",
      expr = [[sum by (namespace) (rate(istio_requests_total{tng_environment="$environment"}[$window]))]],
    },
    {
      title = "Targets up",
      type = "stat",
      ds = "mimir",
      expr = [[count(up{tng_environment="$environment"})]],
    },
    {
      title = "Errors",
      type = "logs",
      ds = "loki",
      expr = [[{tng_environment="$environment"} |= "error"]],
    },
  },
}
