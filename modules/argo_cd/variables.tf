variable "namespace" {
  description = "Kubernetes namespace для Argo CD"
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "Версія Helm чарта Argo CD"
  type        = string
  default     = "6.7.11"
}

variable "git_repo_url" {
  description = "URL Git репозиторію, за яким стежить Argo CD"
  type        = string
}

variable "target_revision" {
  description = "Git гілка/тег/комміт, який відстежує Argo CD"
  type        = string
  default     = "main"
}

variable "django_app_path" {
  description = "Шлях до Helm чарта django-app у репозиторії"
  type        = string
  default     = "charts/django-app"
}

variable "django_app_namespace" {
  description = "Kubernetes namespace для Django застосунку"
  type        = string
  default     = "default"
}

variable "values_override" {
  description = "Додаткові Helm values для Argo CD у форматі YAML рядка"
  type        = string
  default     = ""
}
