#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


TMP_FILE=$(mktemp)
trap "rm -f ${TMP_FILE}" EXIT TERM INT


# remove any inactive keys
INACTIVE=$(aws iam list-access-keys | jq -r '.AccessKeyMetadata[] | select(.Status != "Active") | .AccessKeyId')
if [[ -n ${INACTIVE:-}  ]]; then
    echo "remove inactive access keys"
    aws iam delete-access-key --access-key-id $INACTIVE
fi


# store old key in another secret just incase
kubectl delete secret aws-secrets-old || true
echo "Old ACCESS KEY ${AWS_ACCESS_KEY_ID}"
echo "Storing Old Secret."
kubectl create secret generic aws-secrets-old \
    --from-literal=aws-access-key-id=${AWS_ACCESS_KEY_ID} \
    --from-literal=aws-secret-access-key=${AWS_SECRET_ACCESS_KEY}
echo
echo
OLD_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}

aws iam create-access-key > ${TMP_FILE}
AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId ${TMP_FILE})
AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey ${TMP_FILE})
echo "New ACCESS KEY ${AWS_ACCESS_KEY_ID}"

echo "Removing previous secret"
kubectl delete secret aws-secrets || true

echo "Storing New Secret."
kubectl create secret generic aws-secrets-old \
    --from-literal=aws-access-key-id=${AWS_ACCESS_KEY_ID} \
    --from-literal=aws-secret-access-key=${AWS_SECRET_ACCESS_KEY}
echo
echo


echo "Disabling old access key"
aws iam update-access-key --access-key-id $OLD_AWS_ACCESS_KEY_ID --status Inactive

