provider "aws" {
  region  = "us-east-1"
  version = "~> 2.6"
}

# Cluster connection key pair
resource "aws_lightsail_key_pair" "test-cluster-key-pair" {
  name = "test-lightsail-servers-key-pair"

  # Create private key locally for convenience when remoting into the server
  # Create private key locally for convenience when remoting into the server
  provisioner "local-exec" {
    command = "echo '${aws_lightsail_key_pair.test-cluster-key-pair.private_key}' > local-resources/id_rsa"
  }
  provisioner "local-exec" {
    command = "chmod 600 local-resources/id_rsa"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -f local-resources/id_rsa"
  }
}

# Cluster instances
resource "aws_lightsail_instance" "test-lightsail-servers" {
  count = 3
  name  = "test-lightsail-server-${count.index}"

  availability_zone = "us-east-1a"
  blueprint_id      = "ubuntu_18_04"
  bundle_id         = "small_2_0"
  key_pair_name     = aws_lightsail_key_pair.test-cluster-key-pair.name

  connection {
    type        = "ssh"
    host        = self.public_ip_address
    user        = "ubuntu"
    private_key = aws_lightsail_key_pair.test-cluster-key-pair.private_key
  }

  provisioner "remote-exec" {
    inline = [
      "echo y | sudo ufw enable", # Enable Firewall
      "sudo ufw allow 22",
      "sudo apt update",
      "sudo apt install -y docker.io",
      "sudo sysctl net.ipv4.conf.all.arp_accept=1",
    ] # For LizardFS
  }

  # Open up all lightsail ports ( UFW will be used instead )
  # Open up all lightsail ports ( UFW will be used instead )
  provisioner "local-exec" {
    command = "aws --no-verify-ssl --region us-east-1 lightsail put-instance-public-ports --port-infos fromPort=0,toPort=65535,protocol=all --instance-name ${self.name}"
  }
}
