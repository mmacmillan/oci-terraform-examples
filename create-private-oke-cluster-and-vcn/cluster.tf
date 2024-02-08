resource "oci_containerengine_cluster" "new_oke_cluster" {
    //** this can either use vcn native networking, or flannel
	cluster_pod_network_options {
		cni_type = "OCI_VCN_IP_NATIVE"
	}
	compartment_id = var.compartment_id
	endpoint_config {
        //** this ensures the cluster is private, no public ip is generated
		is_public_ip_enabled = "false"
		subnet_id = "${oci_core_subnet.kubernetes_api_endpoint_subnet.id}"
	}
	freeform_tags = {
		"OKEclusterName" = var.cluster_name
	}
	kubernetes_version = var.kubernetes_version
	name = var.cluster_name
	options {
		admission_controller_options {
			is_pod_security_policy_enabled = "false"
		}
		persistent_volume_config {
			freeform_tags = {
				"OKEclusterName" = var.cluster_name
			}
		}
		service_lb_config {
			freeform_tags = {
				"OKEclusterName" = var.cluster_name
			}
		}
		service_lb_subnet_ids = ["${oci_core_subnet.service_lb_subnet.id}"]
	}
    //** you can use either a basic cluster, or an enhanced cluster for additional capablities
	type = "BASIC_CLUSTER"
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}

resource "oci_containerengine_node_pool" "new_oke_cluster_nodepool_1" {
	cluster_id = "${oci_containerengine_cluster.new_oke_cluster.id}"
	compartment_id = var.compartment_id
	freeform_tags = {
		"OKEnodePoolName" = "pool1"
	}
	initial_node_labels {
		key = "name"
		value = var.cluster_name
	}
	kubernetes_version = var.kubernetes_version
	name = "pool1"
	node_config_details {
		freeform_tags = {
			"OKEnodePoolName" = "pool1"
		}
		node_pool_pod_network_option_details {
			cni_type = "OCI_VCN_IP_NATIVE"
            pod_subnet_ids = ["${oci_core_subnet.node_subnet.id}"]
		}

        //** the worker nodes will be distributed across the placement configs easily, dictated by the node_pool_size varable (below)
		placement_configs {
			availability_domain = var.AD_1
			subnet_id = "${oci_core_subnet.node_subnet.id}"
		}
		placement_configs {
			availability_domain = var.AD_2
			subnet_id = "${oci_core_subnet.node_subnet.id}"
		}
		placement_configs {
			availability_domain = var.AD_2
			subnet_id = "${oci_core_subnet.node_subnet.id}"
		}
		size = var.node_pool_size
	}
	node_eviction_node_pool_settings {
		eviction_grace_duration = "PT60M"
	}
	node_shape = var.node_shape

    //** set the memory and ocpus for each worker node here
	node_shape_config {
		memory_in_gbs = var.node_memory
		ocpus = var.node_ocpus
	}
    //** the ocid defined in terraforms.tfvars is the (currently) latest version of oracle linux 8
	node_source_details {
		image_id = var.node_image_ocid
		source_type = "IMAGE"
	}

    //** set a public ssh key here to be able to ssh into each worker node
    ssh_public_key = var.node_pool_ssh_public_key
}
