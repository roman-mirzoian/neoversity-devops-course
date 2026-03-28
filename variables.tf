variable "jenkins_admin_password" {
  description = "Пароль адміністратора Jenkins (передавати через -var або terraform.tfvars)"
  type        = string
  sensitive   = true
}

variable "git_repo_url" {
  description = "URL Git репозиторію (для Jenkinsfile pipeline та Argo CD Application)"
  type        = string
}
