#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset


TMP_FILE=$(mktemp)
trap "rm -f ${TMP_FILE}" EXIT TERM INT

OLD_AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}

aws iam create-access-key > ${TMP_FILE}
AWS_ACCESS_KEY_ID=$(jq -r .AccessKey.AccessKeyId ${TMP_FILE})
AWS_SECRET_ACCESS_KEY=$(jq -r .AccessKey.SecretAccessKey ${TMP_FILE})

aws iam delete-access-key --access-key-id $OLD_AWS_ACCESS_KEY_ID
