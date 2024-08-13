#!/bin/bash
KEY_FILE="/etc/apigee/gitRepos/apigee-samples/exposing-to-internet/MOJ/service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json"
ENV_NAME="iam-protected"


"./clean-up.sh" --AUTH_METHOD  USER_SESSION --ENV_NAME $ENV_NAME
