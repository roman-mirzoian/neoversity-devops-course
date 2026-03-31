output "monitoring_namespace" {
  description = "Namespace де розгорнуто Prometheus + Grafana"
  value       = var.namespace
}

output "grafana_service_name" {
  description = "Назва Kubernetes Service для Grafana"
  value       = "kube-prometheus-stack-grafana"
}

output "prometheus_service_name" {
  description = "Назва Kubernetes Service для Prometheus"
  value       = "kube-prometheus-stack-prometheus"
}

output "alertmanager_service_name" {
  description = "Назва Kubernetes Service для Alertmanager"
  value       = "kube-prometheus-stack-alertmanager"
}

output "grafana_port_forward_command" {
  description = "Команда для доступу до Grafana через port-forward"
  value       = "kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n ${var.namespace}"
}

output "prometheus_port_forward_command" {
  description = "Команда для доступу до Prometheus через port-forward"
  value       = "kubectl port-forward svc/kube-prometheus-stack-prometheus 9090:9090 -n ${var.namespace}"
}

output "alertmanager_port_forward_command" {
  description = "Команда для доступу до Alertmanager через port-forward"
  value       = "kubectl port-forward svc/kube-prometheus-stack-alertmanager 9093:9093 -n ${var.namespace}"
}
