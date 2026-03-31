variable "namespace" {
  description = "Kubernetes namespace для Prometheus + Grafana"
  type        = string
  default     = "monitoring"
}

variable "chart_version" {
  description = "Версія Helm чарта kube-prometheus-stack"
  type        = string
  default     = "56.21.4"
}

variable "grafana_admin_password" {
  description = "Пароль адміністратора Grafana (sensitive)"
  type        = string
  sensitive   = true
}

variable "prometheus_retention" {
  description = "Термін зберігання метрик Prometheus (наприклад: 15d, 30d)"
  type        = string
  default     = "15d"
}

variable "prometheus_storage_size" {
  description = "Розмір PVC для Prometheus (потребує EBS CSI driver)"
  type        = string
  default     = "20Gi"
}

variable "grafana_storage_size" {
  description = "Розмір PVC для Grafana"
  type        = string
  default     = "5Gi"
}

variable "alertmanager_storage_size" {
  description = "Розмір PVC для Alertmanager"
  type        = string
  default     = "2Gi"
}

variable "storage_class" {
  description = "StorageClass для PVC (gp2 — надається EBS CSI driver)"
  type        = string
  default     = "gp2"
}

variable "values_override" {
  description = "Додаткові Helm values у форматі YAML рядка"
  type        = string
  default     = ""
}
