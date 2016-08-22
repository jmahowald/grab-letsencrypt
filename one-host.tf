module "coreos_amis" {
  source = "github.com/terraform-community-modules/tf_aws_coreos_ami"
  region = "${var.aws_region}"
  channel = "stable"
  virttype = "hvm"
}
resource "aws_instance" "registry" {
  #  availability_zone = "${var.aws_availability_zone}"
    ami = "${module.coreos_amis.ami_id}"
    subnet_id = "${terraform_remote_state.vpc.output.public_subnet_id}"
    instance_type = "t2.micro"
    key_name = "${terraform_remote_state.vpc.output.key_name}"
    # Very very weird that I can't use the vpc output for this and have to
    # supply it as a variable. Plus even when I do, it only allows two
    vpc_security_group_ids = ["${terraform_remote_state.vpc.output.security_group_ids}",
      "${aws_security_group.docker_registry.id}",
      "${terraform_remote_state.vpc.output.nat_security_group}",
      "${terraform_remote_state.vpc.output.web_security_group}"]
    tags {
      Name = "registry"
      Owner = "${var.owner}"
    }

    connection {
        user =  "core"
        key_file = "${terraform_remote_state.vpc.output.key_file}"
        /*bastion_host = "${terraform_remote_state.vpc.output.bastion_ip}"
        bastion_user = "${terraform_remote_state.vpc.output.bastion_user}"
        bastion_private_key = "${file(terraform_remote_state.vpc.output.key_file)}" å*/
    }

    provisioner "remote-exec" {
        inline =  [
            "docker run . . .",
        ]
    }

}
