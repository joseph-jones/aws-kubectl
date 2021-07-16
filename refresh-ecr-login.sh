#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


echo "Retrieving Docker Credentials for the AWS ECR Registry ${AWS_ACCOUNT_ID}"
DOCKER_REGISTRY_SERVER=https://${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
DOCKER_USER=AWS
DOCKER_PASSWORD=$(aws ecr get-login-password)

for namespace in ${NAMESPACES}
do
	echo
	echo "Working in Namespace ${namespace}"
	echo
	echo "Removing previous secret in namespace ${namespace}"
	kubectl --namespace=${namespace} delete secret aws-registry || true

	echo "Creating new secret in namespace ${namespace}"
	kubectl create secret docker-registry aws-registry \
		--docker-server=$DOCKER_REGISTRY_SERVER \
		--docker-username=$DOCKER_USER \
		--docker-password=$DOCKER_PASSWORD
	echo
	echo
done
