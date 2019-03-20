terraform {
    required_version = ">= 0.8.7"
}

provider "aws" {
    access_key = "${var.AWS_ACCESS_KEY_ID}"
    secret_key = "${var.AWS_SECRET_ACCESS_KEY}"
    region = "${var.AWS_DEFAULT_REGION}"
}

data "aws_availability_zones" "available" {}

/*
* Calling modules who create the initial AWS VPC
* and AWS IAM Roles for Kubernetes Deployment
*/

module "aws-vpc" {
  source = "modules/vpc"

  aws_cluster_name = "${var.aws_cluster_name}"
  aws_vpc_cidr_block = "${var.aws_vpc_cidr_block}"
  aws_avail_zones="${slice(data.aws_availability_zones.available.names,0,2)}"
  aws_cidr_subnets_public="${var.aws_cidr_subnets_public}"
  default_tags="${var.default_tags}"

}

module "aws-iam" {
  source = "modules/iam"

  aws_cluster_name="${var.aws_cluster_name}"
}

/*
* Create K8s Master and worker nodes and etcd instances
*
*/

resource "aws_instance" "k8s-master" {
    ami = "${data.aws_ami.distro.id}"
    instance_type = "${var.aws_kube_master_size}"

    count = "${var.aws_kube_master_num}"
    associate_public_ip_address = true

    availability_zone  = "${element(slice(data.aws_availability_zones.available.names,0,2),count.index)}"
    subnet_id = "${element(module.aws-vpc.aws_subnet_ids_public,count.index)}"


    vpc_security_group_ids = [ "${module.aws-vpc.aws_security_group}" ]


    iam_instance_profile = "${module.aws-iam.kube-master-profile}"
    key_name = "${var.AWS_SSH_KEY_NAME}"


    tags = "${merge(var.default_tags, map(
      "Name", "kubernetes-${var.aws_cluster_name}-master${count.index}",
      "kubernetes.io/cluster/${var.aws_cluster_name}", "member",
      "Role", "master"
    ))}"
}

resource "aws_instance" "k8s-etcd" {
    ami = "${data.aws_ami.distro.id}"
    instance_type = "${var.aws_etcd_size}"

    count = "${var.aws_etcd_num}"
    associate_public_ip_address = true

    availability_zone = "${element(slice(data.aws_availability_zones.available.names,0,2),count.index)}"
    subnet_id = "${element(module.aws-vpc.aws_subnet_ids_public,count.index)}"


    vpc_security_group_ids = [ "${module.aws-vpc.aws_security_group}" ]

    key_name = "${var.AWS_SSH_KEY_NAME}"

    tags = "${merge(var.default_tags, map(
      "Name", "kubernetes-${var.aws_cluster_name}-etcd${count.index}",
      "kubernetes.io/cluster/${var.aws_cluster_name}", "member",
      "Role", "etcd"
    ))}"

}


resource "aws_instance" "k8s-worker" {
    ami = "${data.aws_ami.distro.id}"
    instance_type = "${var.aws_kube_worker_size}"

    count = "${var.aws_kube_worker_num}"
    associate_public_ip_address = true

    availability_zone  = "${element(slice(data.aws_availability_zones.available.names,0,2),count.index)}"
    subnet_id = "${element(module.aws-vpc.aws_subnet_ids_public,count.index)}"

    vpc_security_group_ids = [ "${module.aws-vpc.aws_security_group}" ]

    iam_instance_profile = "${module.aws-iam.kube-worker-profile}"
    key_name = "${var.AWS_SSH_KEY_NAME}"


    tags = "${merge(var.default_tags, map(
      "Name", "kubernetes-${var.aws_cluster_name}-worker${count.index}",
      "kubernetes.io/cluster/${var.aws_cluster_name}", "member",
      "Role", "worker"
    ))}"

}

/*
* Create Kubespray Inventory File
*
*/
data "template_file" "inventory" {
    template = "${file("${path.module}/templates/inventory.tpl")}"

    vars {
        connection_strings_master = "${join("\n",formatlist("%s ansible_host=%s",aws_instance.k8s-master.*.tags.Name, aws_instance.k8s-master.*.private_ip))}"
        connection_strings_node = "${join("\n", formatlist("%s ansible_host=%s", aws_instance.k8s-worker.*.tags.Name, aws_instance.k8s-worker.*.private_ip))}"
        connection_strings_etcd = "${join("\n",formatlist("%s ansible_host=%s", aws_instance.k8s-etcd.*.tags.Name, aws_instance.k8s-etcd.*.private_ip))}"
        list_master = "${join("\n",aws_instance.k8s-master.*.tags.Name)}"
        list_node = "${join("\n",aws_instance.k8s-worker.*.tags.Name)}"
        list_etcd = "${join("\n",aws_instance.k8s-etcd.*.tags.Name)}"
    }

}

resource "null_resource" "inventories" {
  provisioner "local-exec" {
      command = "echo '${data.template_file.inventory.rendered}' > ${var.inventory_file}"
  }

  triggers {
      template = "${data.template_file.inventory.rendered}"
  }

}
