output "cluster_name" {
  description = "Назва EKS кластера"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "CA сертифікат кластера"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "kubeconfig_command" {
  description = "Команда для налаштування kubectl"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.this.name} --region ${var.region}"
}
