provider "oci" {
    tenancy_ocid = "your-tenancy-id"
    user_ocid = "your-user-id"
    private_key_path = "/path/to/your/private.key"
    fingerprint = "fingerprint-from-oci-console"
    region = "your region"
}
