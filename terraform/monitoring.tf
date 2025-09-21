############################################
# Monitoring stack: Prometheus + Grafana
# Installs kube-prometheus-stack via Helm
############################################

resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  # Pin the chart version if you need deterministic builds
  # version = "58.3.2"

  # Basic settings (adjust as needed)
  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  set {
    name  = "grafana.service.type"
    value = "ClusterIP"
  }

  set {
    name  = "prometheus.service.type"
    value = "ClusterIP"
  }

  # Optional: reduce noisy default rule groups for small clusters
  set {
    name  = "defaultRules.rules.kubeControllerManager"
    value = "false"
  }
  set {
    name  = "defaultRules.rules.kubeScheduler"
    value = "false"
  }

  depends_on = [
    module.eks
  ]
}
