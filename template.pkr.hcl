packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "my_vm" {
  region        = "us-east-1"
  source_ami    = "ami-04b4f1a9cf54c11d0"
  instance_type = "t3.micro"
  ssh_username  = "ubuntu"
  ami_name      = "my-vm-image-${formatdate("YYYYMMDD-hhmmss", timestamp())}"
  vpc_id        = "vpc-0e320e06aabdb1cb0"
  subnet_id     = "subnet-07167df56df6d3016"

  #temporary_key_pair_type = "ed25519"
}

build {
  sources = [
    "source.amazon-ebs.my_vm"
  ]

  provisioner "file" {
    source      = "main.py"
    destination = "/tmp/main.py"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python3-pip",
      "python3 /tmp/main.py"
    ]
  }
}
