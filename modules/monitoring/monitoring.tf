resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = var.namespace
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version

  timeout         = 600
  cleanup_on_fail = true

  skip_crds = false

  values = [
    templatefile("${path.module}/values.yaml", {
      prometheus_retention      = var.prometheus_retention
      prometheus_storage_size   = var.prometheus_storage_size
      grafana_storage_size      = var.grafana_storage_size
      alertmanager_storage_size = var.alertmanager_storage_size
      storage_class             = var.storage_class
    }),
    var.values_override,
  ]

  set_sensitive {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }

  depends_on = [kubernetes_namespace.monitoring]
}
