### Create a new Apigee Environment and expose to the internet

You need to provide your certificate files (cer and key ) instead of the default certificate managed by google cloud.
and update the create-iam-protected.sh with your certificate 

For example

## Create iam-protected Environment

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
  
## Delete iam-protected Environment

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

