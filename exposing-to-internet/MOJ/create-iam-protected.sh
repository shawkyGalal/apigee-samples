#!/bin/bash

KEY_FILE="/etc/apigee/gitRepos/apigee-samples/exposing-to-internet/MOJ/service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json"
PROJECT="moj-prod-apigee"
ENV_NAME=iam-protected
ENV_GROUP_DNS=apis.moj.gov.sa
TLS_CERT_PATH="./Certificates/2024/te_cb83fa55_4c30_45ee_93e4_b51dd9e5f992.cer"
TLS_KEY_PATH="./Certificates/2024/te_cb83fa55_4c30_45ee_93e4_b51dd9e5f992.key"



"./create-env.sh" --AUTH_METHOD  USER_SESSION --PROJECT $PROJECT --KEY_FILE $KEY_FILE --ENV_NAME $ENV_NAME --ENV_GROUP_DNS $ENV_GROUP_DNS --TLS_CERT_PATH $TLS_CERT_PATH  --TLS_KEY_PATH $TLS_KEY_PATH
