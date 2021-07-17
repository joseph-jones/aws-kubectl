#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


TMP_FILE=$(mktemp)
trap "rm -f ${TMP_FILE}" EXIT TERM INT

OLD_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
echo "Old ACCESS KEY ${OLD_AWS_ACCESS_KEY_ID}"

aws iam create-access-key > ${TMP_FILE}
AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId ${TMP_FILE})
AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey ${TMP_FILE})
echo "New ACCESS KEY ${AWS_ACCESS_KEY_ID}"

echo "Deleting ${OLD_AWS_ACCESS_KEY_ID}"
aws iam delete-access-key --access-key-id $OLD_AWS_ACCESS_KEY_ID

echo "Removing previous secret"
kubectl delete secret aws-secrets || true

cat <<EOL > ${TMP_FILE}
apiVersion: v1
kind: Secret
metadata:
  name: aws-secrets
data:
  aws-access-key-id: ${AWS_ACCESS_KEY_ID}
  aws-secret-access-key: ${AWS_SECRET_ACCESS_KEY}

EOL

echo "Creating new secret"
kubectl apply -f ${TMP_FILE}
