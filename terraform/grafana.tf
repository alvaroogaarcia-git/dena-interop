resource "grafana_data_source" "prometheus" {
  type        = "prometheus"
  name        = "Prometheus"
  uid         = "prometheus"
  url         = "http://monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
  access_mode = "proxy"
  is_default  = true
}

resource "grafana_data_source" "loki" {
  type        = "loki"
  name        = "Loki"
  uid         = "loki"
  url         = "http://loki.monitoring.svc.cluster.local:3100"
  access_mode = "proxy"
  is_default  = false

  json_data_encoded = jsonencode({
    maxLines = 1000
  })
}

resource "grafana_data_source" "tempo" {
  type        = "tempo"
  name        = "Tempo"
  uid         = "tempo"
  url         = "http://tempo.monitoring.svc.cluster.local:3200"
  access_mode = "proxy"
  is_default  = false

  json_data_encoded = jsonencode({
    serviceMap = {
      datasourceUid = grafana_data_source.prometheus.uid
    }
    tracesToLogsV2 = {
      datasourceUid      = grafana_data_source.loki.uid
      spanStartTimeShift = "-15m"
      spanEndTimeShift   = "15m"
      tags = [
        {
          key   = "service.name"
          value = "service.name"
        },
        {
          key   = "k8s.namespace.name"
          value = "k8s.namespace.name"
        },
        {
          key   = "k8s.pod.name"
          value = "k8s.pod.name"
        }
      ]
      filterByTraceID = false
      filterBySpanID  = false
      customQuery     = false
    }
    nodeGraph = {
      enabled = true
    }
  })
}

resource "grafana_folder" "dena" {
  title = "DENA"
  uid   = "dena"
}

resource "grafana_dashboard" "dena_stack_overview" {
  folder      = grafana_folder.dena.uid
  config_json = file("${path.module}/dashboards/dena-stack-overview.json")
  overwrite   = true

  depends_on = [
    grafana_data_source.prometheus,
    grafana_data_source.loki,
    grafana_data_source.tempo
  ]
}

resource "grafana_dashboard" "dena_postgresql_overview" {
  folder      = grafana_folder.dena.uid
  config_json = file("${path.module}/dashboards/dena-postgresql-overview.json")
  overwrite   = true

  depends_on = [
    grafana_data_source.prometheus
  ]
}
