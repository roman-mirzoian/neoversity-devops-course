variable "cluster_name" {
  description = "Назва EKS кластера"
  type        = string
}

variable "cluster_version" {
  description = "Версія Kubernetes"
  type        = string
  default     = "1.29"
}

variable "region" {
  description = "AWS регіон"
  type        = string
}

variable "subnet_ids" {
  description = "Список subnet IDs для control plane"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Список subnet IDs для node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Бажана кількість нод"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Мінімальна кількість нод"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Максимальна кількість нод"
  type        = number
  default     = 6
}

variable "node_instance_types" {
  description = "Типи інстансів для нод"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_capacity_type" {
  description = "Тип capacity для нод: ON_DEMAND або SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "node_disk_size" {
  description = "Розмір диска (GiB)"
  type        = number
  default     = 20
}
