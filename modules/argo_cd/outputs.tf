output "argocd_namespace" {
  description = "Namespace де розгорнуто Argo CD"
  value       = var.namespace
}

output "argocd_admin_secret_name" {
  description = "Назва секрету з початковим паролем адміністратора Argo CD"
  value       = "argocd-initial-admin-secret"
}

output "argocd_server_service" {
  description = "Назва Kubernetes Service для Argo CD сервера"
  value       = "argocd-server"
}
