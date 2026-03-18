variable "repository_name" {
  description = "Ім'я репозиторію ECR"
  type        = string
}

variable "image_tag_mutability" {
  description = "Політика mutability тегів"
  type        = string
  default     = "MUTABLE"
}

variable "scan_on_push" {
  description = "Увімкнути автоматичне сканування образів"
  type        = bool
  default     = true
}
