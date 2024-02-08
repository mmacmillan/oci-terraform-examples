compartment_id = "your-compartment-id"
cluster_name = "mike_test_cluster1"
dns_name = "mtc1"
kubernetes_version = "v1.28.2"
node_pool_size = "1"
node_pool_ssh_public_key = "insert pub-rsa key here"

# Oracle Linux 8.8 (recent)
node_image_ocid = "ocid1.image.oc1.iad.aaaaaaaaszr5wpipg6qskiol3fhbitm56qdmumpbcpv6irzxuofi2nfmlhma" 
node_shape = "VM.Standard.E3.Flex"
node_ocpus = "1"
node_memory = "16"

# ADs for the nodepool placement config
AD_1 = "AWPD:US-ASHBURN-AD-1"
AD_2 = "AWPD:US-ASHBURN-AD-2"
AD_3 = "AWPD:US-ASHBURN-AD-3"
