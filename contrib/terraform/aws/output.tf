output "masters" {
    value = "${join("\n", aws_instance.k8s-master.*.private_ip)}"
}

output "workers" {
    value = "${join("\n", aws_instance.k8s-worker.*.private_ip)}"
}

output "etcd" {
    value = "${join("\n", aws_instance.k8s-etcd.*.private_ip)}"
}

output "inventory" {
    value = "${data.template_file.inventory.rendered}"
}

output "default_tags" {
    value = "${var.default_tags}"
}
