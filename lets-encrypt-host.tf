
# TODO, this should be a list
variable "ssh_keypath" {}
variable "key_name" {}
variable "vpc_id" {}
variable "public_subnet_id" {}

variable "hostedzone" {}
variable "hostname" {}
variable "owner_email" {}

//coreos amis
variable "channel" {
  default = "stable"
}
variable "virtualization_type" {
  default = "hvm"
}

variable "certdir" {
  default = "/var/certs/letsencrypt"
}

data "template_file" "getcerts" {
  template = "${file("grabcert.sh.tpl")}"
  vars {
    certdir = "${var.certdir}"
    owner_email = "${var.owner_email}"
    fqdn = "${aws_route53_record.server_hostname.fqdn}"
  }
}


resource "null_resource" "run_certget" {
  # Rerun if any of these change
  triggers {
    fqdn = "${aws_route53_record.server_hostname.fqdn}"
    instance_id = "${aws_instance.default.id}"
  }
  connection {
    user = "core"
    host = "${var.hostname}"
    private_key = "${file(var.ssh_keypath)}"
  }

  provisioner "remote-exec" {
    inline=[
      "cat << 'DOCKER_GET_CERT_SCRIPT' > /tmp/get_cert.sh",
      "${data.template_file.getcerts.rendered}",
      "DOCKER_GET_CERT_SCRIPT",
      "sudo chmod 755 /tmp/get_cert.sh",
      "sudo /tmp/get_cert.sh",
      "sudo mkdir -p ${var.certdir}",
      // Not exactly the most secure thing, but this
      // instance should be deleted
      "sudo chown -R core ${var.certdir}",
      "/tmp/get_cert.sh",
    ]
  }

  provisioner "local-exec" {
     //Rsyncs over the files.  While it seems insecure to not do host key checking
     //that interferes with automation, plus we JUST created this host seconds ago
     //
      command = <<EOC
rsync -avzh -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i keys/staging.pem' \
        core@rancher.sandbox.backpackhealth.com:/var/certs/letsencrypt certs
  EOC
   }
}


resource "aws_route53_record" "server_hostname" {
    zone_id = "${var.hostedzone}"
    name = "${var.hostname}"
    type = "A"
    ttl = "30"
    records = [
        "${aws_instance.default.public_ip}"
    ]
    lifecycle {
        create_before_destroy = true
    }
}


data "aws_ami" "coreos" {
  most_recent = true
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["${var.virtualization_type}"]
  }
  filter {
    name   = "name"
    values = ["CoreOS-${var.channel}-*"]
  }
}


resource "aws_instance" "default" {
  #  availability_zone = "${var.aws_availability_zone}"
    ami = "${data.aws_ami.coreos.image_id}"
    subnet_id = "${var.public_subnet_id}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    vpc_security_group_ids = ["${aws_security_group.allow_http_and_ssh.id}"]
    tags {
      Name = "certificategrabber"

    }
    associate_public_ip_address="true"

    connection {
        user =  "core"
        private_key = "${file(var.ssh_keypath)}"
    }
}

output "instance_id" {
  value = "${aws_instance.default.id}"
}

output "address" {
  value = "${aws_instance.default.public_ip}"
}
resource "aws_security_group" "allow_http_and_ssh" {
  name = "allow_http_and_ssh"
  description = "Allow http inbound traffic"
  vpc_id = "${var.vpc_id}"
  ingress {
      from_port = 80
      to_port = 80
       protocol = "tcp"

      cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port =443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

}
