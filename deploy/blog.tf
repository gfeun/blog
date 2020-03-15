variable "ssh_private_key_file" {}
variable "blog_fqdn" {
  default = "blog.hackervaillant.eu"
}

data "digitalocean_ssh_key" "default" {
  name = "default"
}

resource "digitalocean_droplet" "blog" {
  image = "debian-10-x64"
  name = "blog"
  region = "lon1"
  size = "1GB"
  private_networking = true
  ssh_keys = [data.digitalocean_ssh_key.default.fingerprint]
}

resource "null_resource" "ansible_provisionning" {

  provisioner "remote-exec" {
    inline = [
      "echo hello",
    ]
    connection {
      type     = "ssh"
      user     = "root"
      private_key = file(var.ssh_private_key_file)
      host     = digitalocean_droplet.blog.ipv4_address
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook --user root --private-key '${var.ssh_private_key_file}' -i '${digitalocean_droplet.blog.ipv4_address},' -e 'blog_fqdn=${var.blog_fqdn}' playbook.yml"
    environment = {
      "ANSIBLE_HOST_KEY_CHECKING" = "False"
      "PRIVATE_KEY" = acme_certificate.blog_certificate.private_key_pem
      "CERTIFICATE" = acme_certificate.blog_certificate.certificate_pem
    }
  }
}

# Create a new domain and A record
resource "digitalocean_domain" "blog" {
  name       = "blog.hackervaillant.eu"
  ip_address = digitalocean_droplet.blog.ipv4_address
}

provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "gfeun@protonmail.com"
}

resource "acme_certificate" "blog_certificate" {
  account_key_pem           = acme_registration.reg.account_key_pem
  common_name               = "blog.hackervaillant.eu"

  dns_challenge {
    provider = "digitalocean"
    config = {
      DO_AUTH_TOKEN = var.do_token
    }
  }
}
