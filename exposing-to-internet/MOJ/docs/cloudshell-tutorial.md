### Create a new Apigee Environment and expose to the internet

You need to provide your certificate files (cer and key ) instead of the default certificate managed by google cloud.
and update the create-iam-protected.sh with your certificate 

For example

## Create iam-protected Environment


 ```
 	cd ./exposing-to-internet
 	sudo chmod 777 ./MOJ/create-iam-protected.sh
 	sudo chmod 777 ./MOJ/create-env.sh
  	./MOJ/create-iam-protected.sh
  
  ```
  
  
## Delete iam-protected Environment

 ```
  cd ./exposing-to-internet
  sudo chmod 777 ./MOJ/delete-iam-protected.sh
  sudo chmod 777 ./MOJ/clean-up.sh
  ./MOJ/delete-iam-protected.sh
  
 ```
