#Global Vars
aws_cluster_name = "sw-practical-ha"

#VPC Vars
aws_vpc_cidr_block = "74.125.192.0/18"
aws_cidr_subnets_private = ["74.125.192.0/20","74.125.208.0/20"]
aws_cidr_subnets_public = ["74.125.224.0/20","74.125.240.0/20"]

#Bastion Host
aws_bastion_size = "t2.small"

#Kubernetes Cluster

aws_kube_master_num = 3
aws_kube_master_size = "t2.medium"

aws_etcd_num = 3
aws_etcd_size = "t2.small"

aws_kube_worker_num = 3
aws_kube_worker_size = "t2.small"

#Settings AWS ELB

aws_elb_api_port = 6443
k8s_secure_api_port = 6443
kube_insecure_apiserver_address = "0.0.0.0"

default_tags = {
#  Env = "sw-practical-ha"
#  Product = "kubernetes-kubespray-ha"
}

inventory_file = "../../../inventory/hosts-aws-ha"
