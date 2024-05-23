#!/bin/bash

set -e -o pipefail

if [ -z "$upload_filepath" ]; then
  echo "Please provide location of the APK or IPA file to upload"
  exit 1
fi

if [ ! -f "$upload_filepath" ]; then
  echo "Provided APK or IPA file does not exist: $upload_filepath"
  exit 1
fi

if [ -z "$mobitru_access_key" ]; then
  echo "Please provide your Mobitru access key"
  exit 1
fi

if [ -z "$mobitru_billing_unit_slug" ]; then
  echo "Please provide your Mobitru billing unit slug"
  exit 1
fi

if [ -z "$share_with_team" ]; then
  echo "Please provide share with the team parameter"
  exit 1
fi

if [ -z "$mobitru_address" ]; then
  echo "Please provide address of target Mobitru instance"
  exit 1
fi

optional_args=()

if [ -n "$artifact_alias" ]; then
  optional_args+=(-H "X-Alias: $artifact_alias")
fi

if [ "$share_with_team" = 'yes' ]; then
  optional_args+=(-H 'X-Private: false')
elif [ "$share_with_team" = 'no' ]; then
  optional_args+=(-H 'X-Private: true')
else
  echo "Invalid 'Share with team' value: $share_with_team"
  exit 1
fi

echo "Uploading $upload_filepath to $mobitru_billing_unit_slug team space:"

response=$(curl -sS --fail-with-body \
  -H "Authorization: Bearer ${mobitru_access_key}" \
  -H "X-File-Name: $(basename "${upload_filepath}")" \
  -H "X-Content-Type: application/zip" \
  -F "file=@${upload_filepath}" \
  "${optional_args[@]}" \
  "${mobitru_address%/}/billing/unit/${mobitru_billing_unit_slug}/automation/api/v1/spaces/artifacts" | tee /dev/fd/2)

artifact_id=$(echo "$response" | jq -j '.id')
echo -e "\nUploaded artifact ID: ${artifact_id}"

envman add --key MOBITRU_ARTIFACT_ID --value "${artifact_id}"
