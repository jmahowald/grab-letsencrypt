
variable "aws_region"{}
# TODO, this should be a list
variable "aws_availability_zone" {}
variable "owner" {}
variable "environment_name"{}
variable "ssh_keypath" {}
variable "key_name" {}
variable "public_subnet_id" {}
variable "security_group_ids" {
  type = "list"
}


module "coreos_amis" {
  source = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region = "${var.aws_region}"
  channel = "stable"
  virttype = "hvm"
}


resource "aws_instance" "registry" {
  #  availability_zone = "${var.aws_availability_zone}"
    ami = "${module.coreos_amis.ami_id}"
    subnet_id = "${var.public_subnet_id}"
    instance_type = "t2.micro"
    key_name = "${var.key_name}"
    # Very very weird that I can't use the vpc output for this and have to
    # supply it as a variable. Plus even when I do, it only allows two
    vpc_security_group_ids = ["${var.security_group_ids}",
      "${aws_security_group.docker_registry.id}",
      "${var.nat_security_group}",
      "${var.web_security_group}"]
    tags {
      Name = "registry"
      Owner = "${var.owner}"
    }

    connection {
        user =  "core"
        key_file = "${var.key_file}"
    }

    provisioner "remote-exec" {
        inline =  [
            "docker run . . .",
        ]
    }

}
