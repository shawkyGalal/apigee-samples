### Create a new Apigee Environment and expose to the internet

You need to provide your certificate files (cer and key ) instead of the default certificate managed by google cloud.
and update the create-iam-protected.sh with your certificate 

For example

## Create iam-protected Environment


 ```
 	cd ./exposing-to-internet/MOJ
 	sudo chmod 777 ./create-iam-protected.sh
 	sudo chmod 777 ./create-env.sh
  	./create-iam-protected.sh
  
  ```
  
  
## Delete iam-protected Environment

 ```
  cd ./exposing-to-internet/MOJ
  sudo chmod 777 ./delete-iam-protected.sh
  sudo chmod 777 ./clean-up.sh
  ./delete-iam-protected.sh
  
 ```
