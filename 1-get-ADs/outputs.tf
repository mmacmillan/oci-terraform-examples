output "all-availability-domains" {
    value = data.oci_identity_availability_domains.ids.availability_domains
}
