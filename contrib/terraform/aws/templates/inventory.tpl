[all]
${connection_strings_master}
${connection_strings_node}
${connection_strings_etcd}

[kube-master]
${list_master}

[kube-node]
${list_node}

[etcd]
${list_etcd}

[k8s-cluster:children]
kube-node
kube-master
