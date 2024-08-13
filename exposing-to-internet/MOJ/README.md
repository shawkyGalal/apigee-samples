# Exposing Apigee Instances to the Internet

This sample shows how to expose an Apigee instance to the internet using a [Google Cloud external HTTP(S) Load Balancer](https://cloud.google.com/load-balancing/docs/https) and [Private Service Connect](https://cloud.google.com/apigee/docs/api-platform/system-administration/northbound-networking-psc).

## How it works

With Apigee X, customers have full control over whether or not to expose their [runtime](https://cloud.google.com/apigee/docs/api-platform/get-started/what-apigee#componentsofapigeeedge-edgeapiservices) instances externally. Apigee X instances are not exposed to the internet by default, however customers may choose to serve traffic to external API consumers by placing an external HTTP(S) load balancer in front of Apigee. Customers may then leverage other features of Google Cloud Load Balancing such as [Cloud Armor](https://cloud.google.com/armor) WAF & DDoS protection for additional security in front of their APIs.

When following the Apigee X [provisioning wizard](https://cloud.google.com/apigee/docs/api-platform/get-started/wizard-select-project), you will be prompted to [configure access routing](https://cloud.google.com/apigee/docs/api-platform/get-started/configure-routing) for your newly created instance. If you choose the internal option, the instance is only accessible internally via your GCP VPC network. If you subsequently decide you wish to expose it externally, this sample shows how to add the load balancer. The sample creates a sample environment and environment group, then reserves a static IP address and creates a load balancer with a [Google managed TLS certificate](https://cloud.google.com/load-balancing/docs/ssl-certificates/google-managed-certs) and an external hostname using [nip.io](https://nip.io/) to resolve to the IP.

## Northbound Routing With Private Service Connect (PSC)

This sample makes use of GCP's [Private Service Connect](https://cloud.google.com/vpc/docs/private-service-connect) (aka PSC) capability to connect an external load balancer to the Apigee X instance.  Apigee supports PSC for both [northbound](https://cloud.google.com/apigee/docs/api-platform/system-administration/northbound-networking-psc) (ingress) and [southbound](https://cloud.google.com/apigee/docs/api-platform/architecture/southbound-networking-patterns-endpoints) (egress) connectivity.  This sample only deals with use of PSC for northbound connections from the internet.

Each Apigee X instance contains a PSC [Service Attachment](https://cloud.google.com/vpc/docs/about-vpc-hosted-services#service-attachments). Information about the attachment can be found on the [Instances](https://cloud.google.com/apigee/docs/api-platform/system-administration/instances) page in the Apigee management UI, or via the [`organizations.instances.get`](https://cloud.google.com/apigee/docs/reference/apis/apigee/rest/v1/organizations.instances/get) API method.

Customers can connect an external load balancer to this attachment using a [PSC network endpoint group](https://cloud.google.com/load-balancing/docs/negs#psc-neg), or PSC NEG for short.  PSC provides a fully managed option to establish connectivity, which does not involve the use of network bridge VMs.   The high level architecture is depicted in the diagram below:

![Architecture](https://cloud.google.com/static/apigee/docs/api-platform/images/psc-arch.png)

## Screencast

[![Alt text](https://img.youtube.com/vi/LlE05zlfnlA/0.jpg)](https://www.youtube.com/watch?v=LlE05zlfnlA)

## Prerequisites

1. An Apigee X instance already provisioned. If not, you may follow the steps [here](https://cloud.google.com/apigee/docs/api-platform/get-started/provisioning-intro).
2. Your account must have [permissions to configure access routing](https://cloud.google.com/apigee/docs/api-platform/get-started/permissions#access-routing-permissions) and create Apigee environment and environment groups. See the predefined roles listed [here](https://cloud.google.com/apigee/docs/api-platform/get-started/permissions#predefined-roles).
2. Make sure the following tools are available in your terminal's `$PATH` (Cloud Shell has these preconfigured)
    * [gcloud SDK](https://cloud.google.com/sdk/docs/install)
    * curl
    * jq
    * npm

## (QuickStart) Setup using CloudShell

Use the following GCP CloudShell tutorial, and follow the instructions.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.png)](https://ssh.cloud.google.com/cloudshell/open?cloudshell_git_repo=https://github.com/shawkyGalal/apigee-samples&cloudshell_git_branch=main&cloudshell_workspace=.&cloudshell_tutorial=exposing-to-internet/docs/cloudshell-tutorial.md)
### Create a new Apigee Environment and expose to the internet

You need to provide your certificate files (cer and key ) instead of the default certificate managed by google cloud.
and update the create-iam-protected.sh with your certificate 

For example 
To Create iam-protected Environment

 ```bash
PROJECT=moj-prod-apigee
ENV_NAME=iam-protected
ENV_GROUP_DNS=apis.moj.gov.sa
# Certificate files should match with the provided ENV_GROUP_DNS 
TLS_CERT_PATH= "<PATH-TO_CERT_FILE>" # "./Certificates/2024/te_cb83fa55_4c30_45ee_93e4_b51dd9e5f992.cer"
TLS_KEY_PATH="<PATH_TO_KEY_FILE>"  # "./Certificates/2024/te_cb83fa55_4c30_45ee_93e4_b51dd9e5f992.key"


 cd exposing-to-internet/MOJ
 sudo chmod 777 create-env.sh
 sudo chmod 777 create-iam-protected.sh
  
 "./create-env.sh" \
--PROJECT $PROJECT \
--ENV_NAME $ENV_NAME \
--ENV_GROUP_DNS $ENV_GROUP_DNS \
--TLS_CERT_PATH $TLS_CERT_PATH  \
--TLS_KEY_PATH $TLS_KEY_PATH \
--AUTH_METHOD CLOUD_SHELL  \  
# In Case you need to run outside google cloud shell uncomment the following line  
# --AUTH_METHOD SERVICE_KEY  KEY_FILE="./service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json" \
# also no need for PROJECT argument as it will be read from the provided key file 

 ```
 or Simply : 
 
 ```
 	sudo chmod 777 ./MOJ/create-iam-protected.sh
  	sudo ./MOJ/create-iam-protected.sh
  
  ```
  
To delete iam-protected Environment

 ```bash
cd exposing-to-internet/MOJ
chmod 777 clean-up.sh
"./clean-up.sh" \
--PROJECT $PROJECT \
--ENV_NAME $ENV_NAME \
--AUTH_METHOD CLOUD_SHELL \ 
# In Case you need to run outside google cloud shell uncomment the following line  
# --AUTH_METHOD SERVICE_KEY  KEY_FILE="./service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json" \

 ```
 or Simply : 
 
 ```
  cd exposing-to-internet
  sudo chmod 777 ./MOJ/delete-iam-protected.sh
  sudo ./MOJ/delete-iam-protected.sh
  
 ```

## Cleanup

If you want to clean up the artifacts from this example, first source your `env.sh` script, and then run

```bash
./clean-up.sh
```
