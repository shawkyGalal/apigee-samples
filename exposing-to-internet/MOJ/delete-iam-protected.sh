#!/bin/bash
KEY_FILE="/etc/apigee/gitRepos/apigee-samples/exposing-to-internet/service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json"
ENV_NAME="iam-protected"


"./clean-up.sh" --KEY_FILE $KEY_FILE --ENV_NAME $ENV_NAME
