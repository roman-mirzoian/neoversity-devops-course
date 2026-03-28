variable "namespace" {
  description = "Kubernetes namespace для Jenkins"
  type        = string
  default     = "jenkins"
}

variable "chart_version" {
  description = "Версія Helm чарта Jenkins"
  type        = string
  default     = "5.1.25"
}

variable "admin_user" {
  description = "Ім'я адміністратора Jenkins"
  type        = string
  default     = "admin"
}

variable "admin_password" {
  description = "Пароль адміністратора Jenkins"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "Назва EKS кластера (для іменування IRSA ролі)"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL з EKS кластера (для IRSA)"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN ECR репозиторію, до якого Jenkins потребує push-доступу"
  type        = string
}

variable "aws_region" {
  description = "AWS регіон (використовується в ECR URL)"
  type        = string
}

variable "aws_account_id" {
  description = "AWS Account ID (використовується в ECR URL)"
  type        = string
}

variable "git_repo_url" {
  description = "URL Git репозиторію для Jenkinsfile"
  type        = string
}

variable "git_credentials_id" {
  description = "ID Jenkins credentials для доступу до Git"
  type        = string
  default     = "git-credentials"
}

variable "values_override" {
  description = "Додаткові Helm values у форматі YAML рядка"
  type        = string
  default     = ""
}
