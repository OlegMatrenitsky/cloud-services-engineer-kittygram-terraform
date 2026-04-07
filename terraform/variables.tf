variable "cloud_id" {
  type = string
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-d"
}

variable "static_ip_id" {
  type = string
}

# Object Storage
variable "access_key" {
  type = string
}
variable "secret_key" {
  type = string
}

variable "new_user" {
  type    = string
  default = "cloud-init.txt"
}