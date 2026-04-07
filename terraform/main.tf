terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

  backend "s3" {
    bucket = "terraform-state-cloud"
    key    = "network/terraform.tfstate"
    region = "ru-central1"

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_requesting_account_id  = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }  
}

provider "yandex" {
  zone      = var.zone
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  service_account_key_file = "key.json"
}

# -------------------------
# Сеть
# -------------------------
resource "yandex_vpc_network" "network_practicum" {
  name = "network_practicum"
}

# -------------------------
# Подсеть
# -------------------------
resource "yandex_vpc_subnet" "subnet_1" {
  name           = "subnet_1"
  zone           = var.zone
  network_id     = yandex_vpc_network.network_practicum.id
  v4_cidr_blocks = ["10.133.0.0/24"]
}

# -------------------------
# Статический IP 
# -------------------------
data "yandex_vpc_address" "static_ip" {
  address_id = var.static_ip_id
}

# -------------------------
# Группа безопасности
# -------------------------
resource "yandex_vpc_security_group" "vm_sg" {
  name        = "vm-security-group"
  description = "SSH + HTTP + весь исходящий трафик"

  network_id = yandex_vpc_network.network_practicum.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "SSH"
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "HTTP"
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
    description    = "All outgoing traffic"
  }
}

# -------------------------
# Виртуальная машина
# -------------------------
resource "yandex_compute_instance" "vm-kittygram" {
  name        = "vm-kittygram"
  platform_id = "standard-v3"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8jjccig145ofgp5b9u" # Ubuntu 24.04
      type     = "network-ssd-nonreplicated"
      size     = 93
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet_1.id
    nat       = true
    nat_ip_address     = data.yandex_vpc_address.static_ip.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.vm_sg.id]
  }

  metadata = {
    user-data = file(var.new_user)
  }
}