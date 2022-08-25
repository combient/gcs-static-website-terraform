# GCS static website terraform config

Simple terraform configuration for hosting a static website on GCP with HTTPS support_

This terraform project can be used to create one or more hosted websites backed by 
Google Cloud Storage (GCS). The sites will have a global public IP, reachable using
a DNS name such as www.example.com and require HTTPS. 

## Usage of the repo

You can simply incorporate the code into your project if you want.
If you fork the repository, remember to add this repo as the upstream remote

    git remote add upstream git@github.com:combient/gcs-static-website-terraform.git

So you can refresh your fork later

    git fetch upstream main
    git rebase upstream/main 

## Prerequisites

- You have control over a domain and can edit its DNS-information. 
- You have the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install-sdk) installed. 
- You are authenticated to a GCP project and have sufficient privileges assigned to create 
these resources.
- The backend bucket (see below) exists.

## Preparation

The configuration uses two files that need to be edited to your preferences and situation:
1. `backend.hcl` - Simply names the bucket in which the state is stored
2. `terraform.tfvars` - Your project settings

### Initiate the backend configuration

Create the bucket to store the terraform state. Obviously terraform can't do this, so

    gcloud alpha storage buckets create gs://$TERRAFORM_BUCKET_NAME

where TERRAFORM_BUCKET_NAME is any unique name such as "com_mycorp_pyproj_tfstate".

Create file backend.hcl (or copy `backend.example,hcl`). Enter the unique bucket name $TERRAFORM_BUCKET_NAME. Then:

    terraform init -backend-config=backend.hcl   

### Provide values for project variables

Copy the file `terraform.example.tfvars` to (for example) terraform.tfvars. Edit to your preferences and situation

## Usage

Validate and plan

    terraform plan

Apply the configuration

    terraform apply -auto-approve

**Note that this will take up to half an hour to complete the first time**. It takes time to provision 
the TLS certificate and for DNS changes to propagate. Go have lunch or something. 

You can check on your SSl cert using the command

    gcloud compute ssl-certificates describe $YOUR-CERT-NAME \
    --global \
    --format="get(name,managed.status)"

## Check DNS

The zone created will be assigned DNS servers automatically. You need to make sure your domain is configured to use these
DNS servers. 

Find your zone name (should be project ID with the suffix "-zone")

    gcloud dns managed-zones list

See the list of DNS-servers used by your zone

    gcloud dns record-sets list -z $YOUR_ZONE_NAME

Go to your registrar and enter the listed DNS-servers in the domain DNS configuration. 

You can now visit your site. You will see the auto generated index.html file. 

**Note that it is essential that the DNS resolution works for the TLS certificate to be provisioned 
(otherwise you will see status `FAILED_NOT_VISIBLE`).** If you are delegating to Google Cloud DNS from
some other master DNS server, note that the DNS servers on the google side are assigned automatically,
and you have to update you delegating DNS record accordingly (see above).

## Upload your site

To upload your real site, the gsutil command is handy

    gsutil cp -r your-dir gs://your-bucket