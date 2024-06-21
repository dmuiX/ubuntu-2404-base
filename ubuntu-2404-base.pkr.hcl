packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    vmware = {
      version = "~> 1"
      source = "github.com/hashicorp/vmware"
    }
  }
}

variable "iso_amd_checksum" {
  type    = string
  default = "8762f7e74e4d64d72fceb5f70682e6b069932deedb4949c6975d0f0fe0a91be3"
}

variable "iso_amd_url" {
  type    = string
  default = "https://releases.ubuntu.com/noble/ubuntu-24.04-live-server-amd64.iso"
}

variable "iso_arm_checksum" {
  type    = string
  default = "d2d9986ada3864666e36a57634dfc97d17ad921fa44c56eeaca801e7dab08ad7"
}

variable "iso_arm_url" {
  type    = string
  default = "https://cdimage.ubuntu.com/releases/noble/release/ubuntu-24.04-live-server-arm64.iso"
}

variable "cloudimg_amd_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "cloudimg_amd_checksum" {
  type    = string
  default = "784f6811c7681110cb066c8b4ad2a8fa654ad9c3ed63278286389f4180377600"
}

variable "vm_name" {
  type = string
  default = "ubuntu-2404-base"
}

variable "username" {
  type    = string
  default = "vagrant"
}

variable "password" {
  type    = string
  default = "vagrant"
}

variable "hashed_password" {
  type    = string
  default = "$6$m0w41abFhAR6FqIx$1UkMR.gRPMO4HMLHr5wllojoUMOfW39QFxmvH8k9bKVwSoI3oS6PwqxwtNfqreXSqHYgU1uRUF5EJAGeivXy.."
}

variable "access_token" {
  type    = string
  default = "${env("VAGRANT_CLOUD_TOKEN")}"
}

variable "version" {
  type    = string
  default = "1.0"
}

variable "amd64" {
  type    = string
  default = "amd64"
}

variable "arm" {
  type    = string
  default = "arm"
}

variable "disk_size" {
  type    = string
  default = "128G"
}

variable "format" {
  type    = string
  default = "qcow2"
}

variable "ram" {
  type    = number
  default = 4096
}

variable "cpus" {
  type    = number
  default = 4
}

variable "kvm" {
  type    = string
  default = "kvm"
}

source "qemu" "ubuntu-qemu-amd" {
  disk_size         = "${var.disk_size}"
  format            = "${var.format}"
  memory            = "${var.ram}"
  cpus              = "${var.cpus}"
  accelerator       = "${var.kvm}"
  disk_compression  = true
  disk_interface    = "virtio"
  ssh_username      = "${var.username}"
  ssh_password      = "${var.password}"
  ssh_port          = "22"
  ssh_timeout       = "1h"
  vm_name           = "${var.vm_name}"
  iso_checksum      = "${var.iso_amd_checksum}"
  iso_url           = "${var.iso_amd_url}"
  output_directory  = "${var.vm_name}"
  # boot_wait         = "3s"
  cd_files          = ["user-data", "meta-data"] # https://askubuntu.com/questions/1425812/ubuntu-server-20-04-4-autoinstall-not-loading-user-data-anymore-packer
  cd_label          = "cidata"
  shutdown_command  = "echo 'packer' | sudo -S shutdown -P now"
  # vnc_port_min      = "5955"
  # vnc_port_max      = "5955"
  disable_vnc       = false
  headless          = true
  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall",
    "<f10>"
  ]
}

build {
  # he does not like variables at this stage
  # sources = ["source.qemu.ubuntu-qemu-amd", "source.vmware.ubuntu-vmware-amd", "source.qemu.ubuntu-qemu-arm", "source.vmware.ubuntu-vmware-arm"]
  sources = ["source.qemu.ubuntu-qemu-amd"]

  post-processor "vagrant" {
    keep_input_artifact  = true
    compression_level    = 6
    output               = "${var.vm_name}.box"
  }
  
  post-processor "checksum" {
    checksum_types = ["sha1", "sha256"]
    output = "packer_{{.BuildName}}_{{.ChecksumType}}.checksum"
  }

  post-processor "artifice" {
    files = ["./${var.vm_name}.box"]
  }

  post-processor "vagrant-cloud" {
    access_token = "${var.access_token}"
    box_tag      = "dmuiX/${var.vm_name}.box"
    version      = "${var.version}"
    architecture = "${var.amd64}"
    box_checksum =  "sha256:build.post-processor.checksum"
  }
  
}