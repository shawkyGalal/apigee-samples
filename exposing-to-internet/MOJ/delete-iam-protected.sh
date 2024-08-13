#!/bin/bash
PROJECT="moj-prod-apigee"
KEY_FILE="./service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json"
ENV_NAME="iam-protected"

"./clean-up.sh" --AUTH_METHOD USER_SESSION --PROJECT $PROJECT --ENV_NAME $ENV_NAME
