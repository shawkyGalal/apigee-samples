#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

NETWORK="default"
SUBNET="default"
# KEY_FILE="./service-account-keys/jenkins@moj-prod-apigee.iam.gserviceaccount.com.json"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		--KEY_FILE)
			KEY_FILE="$2"
			echo "====KEY_FILE : $KEY_FILE ======="
			shift # past argument
			shift # past value
			;;              

		--ENV_NAME)
			 ENV_NAME="$2"
			echo "====ENV_NAME : $ENV_NAME ======="
			shift # past argument
			shift # past value
			;;     
      --AUTH_METHOD)
			AUTH_METHOD="$2"
			echo "====AUTH_METHOD : $AUTH_METHOD ======="
			shift # past argument
			shift # past value   
      ;;
      --PROJECT)
			PROJECT="$2"
			echo "====PROJECT : $PROJECT ======="
			shift # past argument
			shift # past value      
		            
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ "$AUTH_METHOD" ="SERVICE_KEY"]; then  
PROJECT=$(cat "$KEY_FILE" | jq --raw-output '.project_id')
fi 

echo "================================================================================================="
echo "=== Start Deleting Environment $ENV_NAME  on Google Cloud Project $PROJECT ===========" 
echo "================================================================================================="

if [ -z "$PROJECT" ]; then
  echo "No PROJECT variable set"
  exit
fi

if ! [ -x "$(command -v jq)" ]; then
  echo "jq command is not on your PATH"
  exit
fi

function wait_for_operation() {

if [ ! -z "$1" ]; then 
 echo "Wating for operation $1 : "
  while true; do
    STATE="$(apigeecli operations get -o "$PROJECT" -n "$1" -t "$TOKEN" | jq --raw-output '.metadata.state')"
    if [ "$STATE" = "FINISHED" ]; then
      echo
      break
    fi
    echo -n .
    sleep 5
  done
 fi
}

if [ "$AUTH_METHOD" ="SERVICE_KEY"]; then  
	gcloud auth login --cred-file $KEY_FILE 
else
	gcloud auth login 
fi

gcloud config set project $PROJECT

echo "Installing apigeecli"
curl -s https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | bash
export PATH=$PATH:$HOME/.apigeecli/bin

TOKEN="$(gcloud auth print-access-token)"

# Get Org and instance information
INSTANCE_JSON=$(apigeecli instances list -o "$PROJECT" -t "$TOKEN")
INSTANCE_NAME=$(echo "$INSTANCE_JSON" | jq --raw-output '.instances[0].name')
REGION=$(echo "$INSTANCE_JSON" | jq --raw-output '.instances[0].location')
    
#"$ENVIRONMENT_GROUP_NAME".$(echo "$RUNTIME_IP" | tr '.' '-').nip.io
ENVIRONMENT_GROUP_NAME=$ENV_NAME"-group"
LOAD_BLANCER_VIP_NAME=$ENV_NAME"-vip"
SSL_CERTIFICATE_NAME=$ENV_NAME"-ssl-cert"
NETWORK_ENDPOINT_GROUP=$ENV_NAME"-neg"
BACKEND_SERVICE_NAME=$ENV_NAME"-backend-service"
URL_MAP_NAME=$ENV_NAME-"urlmap"
TARGET_HTTPS_PROXY_NAME=$ENV_NAME"-https-proxy"
FORWARDING_RULE_NAME=$ENV_NAME"-https-lb-rule"

echo "Deleting load balancer..."
# Delete forwarding rule
gcloud compute forwarding-rules delete $FORWARDING_RULE_NAME \
  --global \
  --project="$PROJECT" --quiet

# Delete target HTTPS proxy
gcloud compute target-https-proxies delete $TARGET_HTTPS_PROXY_NAME \
  --project="$PROJECT" --quiet

# Delete URL map
gcloud compute url-maps delete $URL_MAP_NAME \
  --project="$PROJECT" --quiet

# Delete backend service
gcloud compute backend-services delete $BACKEND_SERVICE_NAME \
  --global \
  --project="$PROJECT" --quiet

# Delete NEG
gcloud compute network-endpoint-groups delete $NETWORK_ENDPOINT_GROUP \
  --region="$REGION" \
  --project="$PROJECT" --quiet

# Delete cert
echo "Deleting SSL certificate..."
gcloud compute ssl-certificates delete $SSL_CERTIFICATE_NAME \
  --project "$PROJECT" --quiet

# Delete VIP
echo "Deleting load balancer IP address..."
gcloud compute addresses delete $LOAD_BLANCER_VIP_NAME \
  --global \
  --project "$PROJECT" --quiet

echo -n "Detaching environment from group..."
OPERATION=$(apigeecli envgroups detach -o "$PROJECT" -e "$ENV_NAME" -n "$ENVIRONMENT_GROUP_NAME" -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

echo -n "Deleting environment group..."
# OPERATION=$(apigeecli envgroups delete -o "$PROJECT" -n "$ENVIRONMENT_GROUP_NAME" -t $TOKEN | jq --raw-output '.name' | awk -F/ '{print $4}')
# Use curl due to https://github.com/apigee/apigeecli/issues/159
OPERATION=$(curl -X DELETE "https://apigee.googleapis.com/v1/organizations/$PROJECT/envgroups/$ENVIRONMENT_GROUP_NAME" -H "Authorization: Bearer $TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

echo -n "Detaching environment from instance..."
OPERATION=$(apigeecli instances attachments detach -o "$PROJECT" -e "$ENV_NAME" -n "$INSTANCE_NAME" -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

echo -n "Deleting environment..."
OPERATION=$(apigeecli environments delete -o "$PROJECT" -e "$ENV_NAME" -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

echo "Clean up complete!"
