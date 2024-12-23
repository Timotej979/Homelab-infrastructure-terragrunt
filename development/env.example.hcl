locals {
    # Set the environment
    environment     = "development" 

    ############################### CLOUD PROVIDERS ###############################

    # Alibaba infrastructure creation configuration
    alibaba_provider_config = {
        enabled    = false
        version    = "~> 1.239.0"
        access_key = "{INSERT ALIBABA ACCESS KEY}"
        secret_key = "{INSERT ALIBABA SECRET KEY}"
        region     = "eu-central-1"
    }

    alibaba_infrastructure_config = {}


    # AWS infrastructure creation configuration
    aws_provider_config = {
        enabled            = false
        version            = "~> 5.82.2"
        profile            = "default"
        region             = "eu-central-1"
        allowed_account_id = "{INSERT ALLOWED ACCOUNT ID}"
    }

    aws_infrastructure_config = {}


    # Azure infrastructure creation configuration
    azure_provider_config = {
        enabled = false
        version = "~> 4.14.0"
        region  = "eu-central-1"
    }

    azure_infrastructure_config = {}


    # Bare Metal infrastructure creation configuration
    baremetal_provider_config = {
        enabled = false
    }

    baremetal_infrastructure_config = {}


    # DigitalOcean infrastructure creation configuration
    digitalocean_provider_config = {
        enabled = false
        version = "~> 2.46.1"
        token   = "{INSERT DO ACCOUNT TOKEN}" 
    }

    digitalocean_infrastrucure_config = {}


    # GCP infrastructure creation configuration
    gcp_provider_config     = {
        enabled = false
        version = "~> 6.14.1"
        credentials_file = "{INSERT GCP CREDENTIALS FILEPATH}"
        project          = "{INSERT GCP PROJECT NAME}"
        region           = "eu-central-1"
    }

    gcp_infrastructure_config = {}


    # Hetzner infrastructure creation configuration
    hetzner_provider_config = {
        enabled = false
        version = "~> 1.49.1"
        token   = "{INSERT HETZNER ACCOUNT TOKEN}"
    }

    hetzner_infrastructure_config = {}


    # Linode infrastructure creation configuration
    linode_provider_config   = {
        enabled = false
        version = "~> 2.31.1"
        token   = "{INSERT LINODE ACCOUNT TOKEN}"
    }

    linode_infrastructure_config = {}


    # OVH infrastructure creation configuration
    ovh_provider_config      = {
        enabled = false
        version = "~> 1.3.0"
        endpoint = "ovh-eu"
        client_id = "{INSERT OVH CLIENT ID}"
        client_secret = "{INSERT OVH CLIENT SECRET}"
    }

    ovh_infrastructure_config = {}


    # Tencent infrastructure creation configuration
    tencent_provider_config = {
        enabled = false
        version = "~> 1.19.0"
        secret_id = "INSERT TENCENT SECRET ID"
        secret_key = "INSERT TENCENT SECRET KEY"
        region = "eu-frankfurt"
    }

    tencent_infrastructure_config = {}


    # Vmware infrastructure creation configuration
    vmware_provider_config   = {
        enabled = false
        version = "~> 0.13.0"
        sddc_manager_host = "{INSERT VMWARE SDDC MANAGER HOST}"
        sddc_manager_username = "{INSERT VMWARE SDDC MANAGER USERNAME}"
        sddc_manager_password = "{INSERT VMWARE SDDC MANAGER PASSWORD}"
        allow_unverified_tls = false
    }

    vmware_infrastructure_config = {}


    





}