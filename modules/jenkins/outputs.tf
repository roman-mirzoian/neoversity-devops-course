output "jenkins_namespace" {
  description = "Namespace де розгорнуто Jenkins"
  value       = var.namespace
}

output "jenkins_service_name" {
  description = "Назва Kubernetes Service для Jenkins"
  value       = "jenkins"
}

output "jenkins_admin_secret_name" {
  description = "Назва Kubernetes секрету з паролем адміністратора Jenkins"
  value       = "jenkins"
}

output "jenkins_irsa_role_arn" {
  description = "ARN IAM ролі для Jenkins (IRSA — доступ до ECR)"
  value       = aws_iam_role.jenkins_irsa.arn
}
