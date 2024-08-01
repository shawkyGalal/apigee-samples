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

# This Script will create a new MOJ GC Apigee Environment

HELP=" createEnv.sh --KEY_FILE <GC_SERVICE_ACCOUNT_KEY_FILE> --VPN <GC_VPN> --VPN_SUBNET <VPN_SUBNET> --PROJECT <PROJECT> --ENV_NAME <ENV_NAME> --ENV_GROUP_DNS <ENV_GROUP_DNS> --INSTANCE_INDEX <INSTANCE_INDEX>  

Parameters : 

AUTH_METHOD     Optional    Default Value = "USER_SESSION" , if = SERVICE_KEY , you should provide a KEY_FILE as a Google Credential
KEY_File 		Conditional In Case AUTH_METHOD=SERVICE_KEY , This Parameter is Mandatory: Google Cloud Service Account Key Used To Create the New Environment
ENV_NAME		Mandatory 	GC Apigee New Environment name 
ENV_GROUP_DNS	Mandatory 	GC Apigee Environment Group Runtime Host Alias that will be associated to the new Environment - Currently This hostname should be *.moj.gov.sa - as Per the Certificate used in this code 
VPN 			Optional 	Google Cloud Virtual Private Network Name		default value = "default"
VPN_SUBNET		Optional	Google Cloud Virtual Private SUB Network Name	default value = "default"
INSTANCE_INDEX	Optional	Apigee Instance Index That Will serve the new Environment  default value = 0 	

" 
INSTANCE_INDEX="0"
VPN="default"
VPN_SUBNET="default"


POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
		-KF|--KEY_FILE)
			 KEY_FILE="$2"
			echo "====KEY_FILE : $KEY_FILE ======="
			shift # past argument
			shift # past value
			;;
		--VPN)
			 VPN="$2"
			echo "====VPN : $VPN ======="
			shift # past argument
			shift # past value
			;;
		--VPN_SUBNET)
			 VPN_SUBNET="$2"
			echo "====VPN_SUBNET : $VPN_SUBNET ======="
			shift # past argument
			shift # past value
			;;

		--ENV_NAME)
			 ENV_NAME="$2"
			echo "====ENV_NAME : $ENV_NAME ======="
			shift # past argument
			shift # past value
			;;              

		--ENV_GROUP_DNS)
			 ENV_GROUP_DNS="$2"
			echo "====ENV_GROUP_DNS : $ENV_GROUP_DNS ======="
			shift # past argument
			shift # past value
			;;
		--TLS_CERT_PATH)
			TLS_CERT_PATH="$2"
			echo "====TLS_CERT_PATH : $TLS_CERT_PATH ======="
			shift # past argument
			shift # past value
			;;
		--TLS_KEY_PATH)
			TLS_KEY_PATH="$2"
			echo "====TLS_KEY_PATH : $TLS_KEY_PATH ======="
			shift # past argument
			shift # past value
			;;
		-h|--help)
    		echo "Usage :"
    		echo "${HELP}"
    		exit
		    ;;
		--INSTANCE_INDEX)
			 INSTANCE_INDEX="$2"
			echo "====INSTANCE_INDEX : $INSTANCE_INDEX ======="
			shift # past argument
			shift # past value
			;;
		--AUTH_METHOD)
			AUTH_METHOD="$2"
			echo "====AUTH_METHOD : $AUTH_METHOD ======="
			shift # past argument
			shift # past value
		            
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters
echo "Inventory File Path  = ${INVENTORY} , Operation = ${OPERATION} ServersGroup= $SERVERS_GROUP"

RUNTIME_HOST_ALIAS=$ENV_GROUP_DNS  #"apis.moj.gov.sa" 
NETWORK=$VPN  #"default"
PROJECT=$(cat "$KEY_FILE" | jq --raw-output '.project_id')

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

INSTANCE_JSON=$(apigeecli instances list -o "$PROJECT" -t "$TOKEN")

# Get Apigee instance information
NAME_REF=.instances[$INSTANCE_INDEX].name
LOC_REF=.instances[$INSTANCE_INDEX].location
ATT_REF=.instances[$INSTANCE_INDEX].serviceAttachment
INSTANCE_NAME=$(echo "$INSTANCE_JSON" | jq --raw-output $NAME_REF)
REGION=$(echo "$INSTANCE_JSON" | jq --raw-output $LOC_REF)
SERVICE_ATTACHMENT=$(echo "$INSTANCE_JSON" | jq --raw-output $ATT_REF)

#"$ENVIRONMENT_GROUP_NAME".$(echo "$RUNTIME_IP" | tr '.' '-').nip.io
ENVIRONMENT_GROUP_NAME=$ENV_NAME"-group"
LOAD_BLANCER_VIP_NAME=$ENV_NAME"-vip"
SSL_CERTIFICATE_NAME=$ENV_NAME"-ssl-cert"
NETWORK_ENDPOINT_GROUP=$ENV_NAME"-neg"
BACKEND_SERVICE_NAME=$ENV_NAME"-backend-service"
URL_MAP_NAME=$ENV_NAME-"urlmap"
TARGET_HTTPS_PROXY_NAME=$ENV_NAME"-https-proxy"
FORWARDING_RULE_NAME=$ENV_NAME"-https-lb-rule"


# Create and attach a sample Apigee environment
echo -n "Creating environment..."
OPERATION=$(apigeecli environments create -o "$PROJECT" -e "$ENV_NAME" -d PROXY  -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

echo -n "Attaching environment to instance (may take a few minutes)..."
OPERATION=$(apigeecli instances attachments attach -o "$PROJECT" -e "$ENV_NAME" -n "$INSTANCE_NAME" -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

# Enable APIs
gcloud services enable compute.googleapis.com --project="$PROJECT" --quiet

# Reserve an IP address for the Load Balancer"
echo "Reserving load balancer IP address..."
gcloud compute addresses create "$LOAD_BLANCER_VIP_NAME" --ip-version=IPV4 --global --project "$PROJECT" --quiet
RUNTIME_IP=$(gcloud compute addresses describe "$LOAD_BLANCER_VIP_NAME" --format="get(address)" --global --project "$PROJECT" --quiet)
# RUNTIME_HOST_ALIAS="$ENVIRONMENT_GROUP_NAME".$(echo "$RUNTIME_IP" | tr '.' '-').nip.io


# Create a sample Apigee environment group and attach the environment
echo -n "Creating environment group..."
OPERATION=$(apigeecli envgroups create -o "$PROJECT" -d "$RUNTIME_HOST_ALIAS" -n "$ENVIRONMENT_GROUP_NAME" -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

echo -n "Attaching environment to group..."
OPERATION=$(apigeecli envgroups attach -o "$PROJECT" -e "$ENV_NAME" -n "$ENVIRONMENT_GROUP_NAME" -t "$TOKEN" | jq --raw-output '.name' | awk -F/ '{print $4}')
wait_for_operation "$OPERATION"

# Create a Google managed SSL certificate
echo "Creating SSL certificate..."
gcloud compute ssl-certificates create $SSL_CERTIFICATE_NAME \
          --certificate=$TLS_CERT_PATH \
		  --private-key=$TLS_KEY_PATH \
		  --project "$PROJECT" --quiet
		  
#gcloud compute ssl-certificates create $SSL_CERTIFICATE_NAME \
#  --domains="$RUNTIME_HOST_ALIAS" --project "$PROJECT" --quiet

## Create a global Load Balancer
echo "Creating external load balancer..."

# Create a PSC NEG
gcloud compute network-endpoint-groups create  $NETWORK_ENDPOINT_GROUP \
  --network-endpoint-type=private-service-connect \
  --psc-target-service="$SERVICE_ATTACHMENT" \
  --region="$REGION" \
  --network="$NETWORK" \
  --subnet="$VPN_SUBNET" \
  --project="$PROJECT" --quiet

# Create a backend service and add the NEG
gcloud compute backend-services create $BACKEND_SERVICE_NAME \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTPS \
  --global --project="$PROJECT" --quiet

gcloud compute backend-services add-backend $BACKEND_SERVICE_NAME \
  --network-endpoint-group="$NETWORK_ENDPOINT_GROUP" \
  --network-endpoint-group-region="$REGION" \
  --global --project="$PROJECT" --quiet

# Create a Load Balancing URL map
gcloud compute url-maps create $URL_MAP_NAME \
  --default-service $BACKEND_SERVICE_NAME --project="$PROJECT" --quiet

# Create a Load Balancing target HTTPS proxy
gcloud compute target-https-proxies create $TARGET_HTTPS_PROXY_NAME \
  --url-map $URL_MAP_NAME \
  --ssl-certificates $SSL_CERTIFICATE_NAME --project="$PROJECT" --quiet

# Create a global forwarding rule
gcloud compute forwarding-rules create $FORWARDING_RULE_NAME \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --network-tier=PREMIUM \
  --address=$LOAD_BLANCER_VIP_NAME --global \
  --target-https-proxy=$TARGET_HTTPS_PROXY_NAME --ports=443 --project="$PROJECT" --quiet


# echo -n "Waiting for certificate provisioning to complete (may take some time)..."
# while true; do
#  TLS_STATUS="$(gcloud compute ssl-certificates describe $SSL_CERTIFICATE_NAME --format=json --project "$PROJECT" --quiet | jq -r '.managed.status')"
#  if [ "$TLS_STATUS" = "ACTIVE" ]; then
#    break
#  fi
#  echo -n .
#  sleep 10
# done

# Pause to allow TLS setup to complete
sleep 120

#echo "Installing dependencies and running tests..."
#npm install
#npm run test

echo " # Create a New local Host file entry : " 
echo "       $RUNTIME_IP  $RUNTIME_HOST_ALIAS"
echo "# To send an EXTERNAL test request, execute the following commands:"
echo "export RUNTIME_HOST_ALIAS=$RUNTIME_HOST_ALIAS"
echo "curl -v https://$RUNTIME_HOST_ALIAS/healthz/ingress -H 'User-Agent: GoogleHC'"
