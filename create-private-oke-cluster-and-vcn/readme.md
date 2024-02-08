# Create Private OKE Cluster and VCN
This example creates a minimal OKE private basic cluster, a VCN, and all the associated VCN resources.  For a cluster using private subnets, a NAT Gateway and Service Gateway is required in the VCN.

## Initializing
Before running the example, you will need to initalize Terraform to install the provider, etc.

```terraform init```

## Configuring
In the terraform.tfvars, replace the `compartment_id` with the id of your target compartment; the cluster and VCN will both be created within this compartment.  Also replace the `node_pool_ssh_public_key` with your public ssh key in order to be able to SSH into the worker nodes after they're created with your public ssh key in order to be able to SSH into the worker nodes after they're created.

## Notes
In `data.tf` we pull a list of oci_core_services so we can dynamically assign the "all services" entry's ocid to the Service Gateway; the order of the items differs when deploying to OC1 vs OC2, so run a `terraform plan` before running `apply` to ensure the entry in `network.tf` is referencing the right entry:

```
resource "oci_core_service_gateway" "new_service_gateway" {
	compartment_id = var.compartment_id
	display_name = "sgw-${ var.cluster_name }"
	services {
        #use the all-services ocid from the core_services for the gateway
		service_id = data.oci_core_services.services.services[1].id <-- HERE
	}
	vcn_id = "${oci_core_vcn.new_vcn.id}"
}
```
