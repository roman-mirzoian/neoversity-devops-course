output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = module.s3-backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = module.s3-backend.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "URL репозиторію ECR"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "Назва EKS кластера"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = module.eks.cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "Команда для оновлення kubeconfig"
  value       = module.eks.kubeconfig_command
}

output "jenkins_namespace" {
  description = "Namespace де розгорнуто Jenkins"
  value       = module.jenkins.jenkins_namespace
}

output "jenkins_irsa_role_arn" {
  description = "IAM роль для Jenkins (IRSA — доступ до ECR)"
  value       = module.jenkins.jenkins_irsa_role_arn
}

output "jenkins_get_password_command" {
  description = "Команда для отримання пароля адміністратора Jenkins"
  value       = "kubectl get secret jenkins -n ${module.jenkins.jenkins_namespace} -o jsonpath='{.data.jenkins-admin-password}' | base64 -d"
}

output "argocd_namespace" {
  description = "Namespace де розгорнуто Argo CD"
  value       = module.argo_cd.argocd_namespace
}

output "argocd_admin_secret_name" {
  description = "Назва секрету з початковим паролем Argo CD"
  value       = module.argo_cd.argocd_admin_secret_name
}

output "argocd_get_password_command" {
  description = "Команда для отримання початкового пароля Argo CD"
  value       = "kubectl get secret argocd-initial-admin-secret -n ${module.argo_cd.argocd_namespace} -o jsonpath='{.data.password}' | base64 -d"
}
