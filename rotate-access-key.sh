#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


TMP_FILE=$(mktemp)
trap "rm -f ${TMP_FILE}" EXIT TERM INT


# remove any inactive keys
INACTIVE=$(aws iam list-access-keys | jq -r '.AccessKeyMetadata[] | select(.Status == "Inactive") | .AccessKeyId')
ACTIVE=$(aws iam list-access-keys | jq -r '.AccessKeyMetadata[] | select(.Status == "Active") | .AccessKeyId')

echo "Active Key ${ACTIVE:-}"
echo "Inactive Key ${INACTIVE:-}"

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

aws iam create-access-key > ${TMP_FILE}

OLD_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
OLD_AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}

AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId ${TMP_FILE})
AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey ${TMP_FILE})

if [[ ${AWS_ACCESS_KEY_ID} == ${OLD_AWS_ACCESS_KEY_ID} ]]; then
    echo "Old and New keys are the same"
fi

if [[ ${AWS_SECRET_ACCESS_KEY} == ${OLD_AWS_SECRET_ACCESS_KEY} ]]; then
    echo "Old and New Secret Keys are the same"
fi

echo "New ACCESS KEY ${AWS_ACCESS_KEY_ID}"

echo "Removing previous secret"
kubectl delete secret aws-secrets || true

echo "Storing New Secret."
kubectl create secret generic aws-secrets \
    --from-literal=aws-access-key-id=${AWS_ACCESS_KEY_ID} \
    --from-literal=aws-secret-access-key=${AWS_SECRET_ACCESS_KEY}
echo
echo


# not sure why I can't deactivate the old key
# I suspect the new key is not ready.
sleep 5
echo "Disabling old access key"
aws iam update-access-key --access-key-id $OLD_AWS_ACCESS_KEY_ID --status Inactive

