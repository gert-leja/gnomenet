resource "local_file" "gen_ansible_inventory" {
	filename = "${path.module}/../ansible/hosts.yml"
	content = templatefile("${path.module}/templates/inventory.tpl", {
	 nodes = [for n in cml_node.this : {
	  name = n.label
	  local_ip = n.local_network
    link_ip = n.link_base_cidr
	  type = n.nodedefinition
	 }]
	})
}