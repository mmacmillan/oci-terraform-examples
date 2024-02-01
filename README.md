# OCI Terraform Examples
This is a collection of simple examples of using Terraform to orchestrate Oracle Cloud Infrastructure (OCI).  Each folder is its own project, so you will need to initiliaze Terraform and configure a provider.tf before running the example.

## Initializing
Before running the example, you will need to initalize Terraform to install the provider, etc.

```terraform init```

## Configuring the OCI Provider
In order to authenticate and execute data requests against OCI, you will need to provide your tenancy credentials in the provider.tf file.  These are the same credentials used with the OCI CLI, so if you have that installed you can pull this info from your ~/.oci/config file.  See [here](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm#configfile) for more information on where to get this info.
```
provider "oci" {
    tenancy_ocid = "your-tenancy-id"
    user_ocid = "your-user-id"
    private_key_path = "/path/to/your/private.key"
    fingerprint = "fingerprint-from-oci-console"
    region = "your region"
}
```
