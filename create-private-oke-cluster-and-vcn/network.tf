/*
    all network resources are defined here: vcn, subnets, route tables, gateways, security lists, etc
*/

//** the new VCN created for the cluster
resource "oci_core_vcn" "new_vcn" {
	cidr_block = "10.0.0.0/16"
	compartment_id = var.compartment_id
	display_name = var.cluster_name
	dns_label = var.dns_name
}

//** internet gateway for allowing traffic to the internet
resource "oci_core_internet_gateway" "new_internet_gateway" {
	compartment_id = var.compartment_id
	display_name = "igw-${ var.cluster_name}"
	enabled = "true"
	vcn_id = oci_core_vcn.new_vcn.id
}

//** nat gateway for routing private ips to the internet
resource "oci_core_nat_gateway" "new_nat_gateway" {
	compartment_id = var.compartment_id
	display_name = "ngw-${ var.cluster_name }"
	vcn_id = oci_core_vcn.new_vcn.id
}

//** service gateway for allowing communication with oracle service network
resource "oci_core_service_gateway" "new_service_gateway" {
	compartment_id = var.compartment_id
	display_name = "sgw-${ var.cluster_name }"
	services {
        #use the all-services ocid from the core_services for the gateway
		service_id = data.oci_core_services.services.services[1].id
	}
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}

//** default route table, configures the Internet gateway
resource "oci_core_default_route_table" "new_default_route_table" {
	display_name = "oke-public-routetable-${ var.cluster_name }"
	route_rules {
		description = "traffic to/from internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = "${oci_core_internet_gateway.new_internet_gateway.id}"
	}
	manage_default_resource_id = "${oci_core_vcn.new_vcn.default_route_table_id}"
}

//** route table for NAT and Service gateways
resource "oci_core_route_table" "new_route_table" {
	compartment_id = var.compartment_id
	display_name = "oke-private-routetable-${ var.cluster_name }"
	route_rules {
		description = "traffic to the internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		network_entity_id = "${oci_core_nat_gateway.new_nat_gateway.id}"
	}
	route_rules {
		description = "traffic to OCI services"
		destination = "all-iad-services-in-oracle-services-network"
		destination_type = "SERVICE_CIDR_BLOCK"
		network_entity_id = "${oci_core_service_gateway.new_service_gateway.id}"
	}
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}

//** load balancer subnet, public, regional
resource "oci_core_subnet" "service_lb_subnet" {
	cidr_block = "10.0.20.0/24"
	compartment_id = var.compartment_id
	display_name = "oke-svclbsubnet-regional-${ var.cluster_name }"
	dns_label = "${ var.dns_name }lbsub"
	prohibit_public_ip_on_vnic = "false"
	route_table_id = "${oci_core_default_route_table.new_default_route_table.id}"
	security_list_ids = ["${oci_core_vcn.new_vcn.default_security_list_id}"]
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}

//** load balancer subnet security list
resource "oci_core_security_list" "service_lb_sec_list" {
	compartment_id = var.compartment_id
	display_name = "oke-svclbseclist-${ var.cluster_name }"
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}


//** worker node subnet, private, regional
resource "oci_core_subnet" "node_subnet" {
	cidr_block = "10.0.10.0/24"
	compartment_id = var.compartment_id
	display_name = "oke-nodesubnet-regional-${ var.cluster_name }"
	dns_label = "${ var.dns_name }nodesub"
	prohibit_public_ip_on_vnic = "true"
	route_table_id = "${oci_core_route_table.new_route_table.id}"
	security_list_ids = ["${oci_core_security_list.node_sec_list.id}"]
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}

//** worker node subnet security list
resource "oci_core_security_list" "node_sec_list" {
	compartment_id = var.compartment_id
	display_name = "oke-nodeseclist-${ var.cluster_name }"
	egress_security_rules {
		description = "Allow pods on one worker node to communicate with pods on other worker nodes"
		destination = "10.0.10.0/24"
		destination_type = "CIDR_BLOCK"
		protocol = "all"
		stateless = "false"
	}
	egress_security_rules {
		description = "Access to Kubernetes API Endpoint"
		destination = "10.0.0.0/28"
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Kubernetes worker to control plane communication"
		destination = "10.0.0.0/28"
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Path discovery"
		destination = "10.0.0.0/28"
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	egress_security_rules {
		description = "Allow nodes to communicate with OKE to ensure correct start-up and continued functioning"
		destination = "all-iad-services-in-oracle-services-network"
		destination_type = "SERVICE_CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "ICMP Access from Kubernetes Control Plane"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	egress_security_rules {
		description = "Worker Nodes access to Internet"
		destination = "0.0.0.0/0"
		destination_type = "CIDR_BLOCK"
		protocol = "all"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Allow pods on one worker node to communicate with pods on other worker nodes"
		protocol = "all"
		source = "10.0.10.0/24"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Path discovery"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		source = "10.0.0.0/28"
		stateless = "false"
	}
	ingress_security_rules {
		description = "TCP access from Kubernetes Control Plane"
		protocol = "6"
		source = "10.0.0.0/28"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Inbound SSH traffic to worker nodes"
		protocol = "6"
		source = "0.0.0.0/0"
		stateless = "false"
	}
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}


//** kubernetes api endpoint subnet, private, regional
resource "oci_core_subnet" "kubernetes_api_endpoint_subnet" {
	cidr_block = "10.0.0.0/28"
	compartment_id = var.compartment_id
	display_name = "oke-k8sApiEndpoint-regional-${ var.cluster_name }"
	dns_label = "${ var.dns_name }okesub"
	prohibit_public_ip_on_vnic = "true"
	route_table_id = "${oci_core_route_table.new_route_table.id}"
	security_list_ids = ["${oci_core_security_list.kubernetes_api_endpoint_sec_list.id}"]
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}

//** kubernetes api endpoint subnet security list
resource "oci_core_security_list" "kubernetes_api_endpoint_sec_list" {
	compartment_id = var.compartment_id
	display_name = "oke-k8sApiEndpoint-${ var.cluster_name }"
	egress_security_rules {
		description = "Allow Kubernetes Control Plane to communicate with OKE"
		destination = "all-iad-services-in-oracle-services-network"
		destination_type = "SERVICE_CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "All traffic to worker nodes"
		destination = "10.0.10.0/24"
		destination_type = "CIDR_BLOCK"
		protocol = "6"
		stateless = "false"
	}
	egress_security_rules {
		description = "Path discovery"
		destination = "10.0.10.0/24"
		destination_type = "CIDR_BLOCK"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		stateless = "false"
	}
	ingress_security_rules {
		description = "External access to Kubernetes API endpoint"
		protocol = "6"
		source = "0.0.0.0/0"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Kubernetes worker to Kubernetes API endpoint communication"
		protocol = "6"
		source = "10.0.10.0/24"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Kubernetes worker to control plane communication"
		protocol = "6"
		source = "10.0.10.0/24"
		stateless = "false"
	}
	ingress_security_rules {
		description = "Path discovery"
		icmp_options {
			code = "4"
			type = "3"
		}
		protocol = "1"
		source = "10.0.10.0/24"
		stateless = "false"
	}
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}


