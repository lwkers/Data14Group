#!/bin/bash

set -e

# Parameters
SCRIPTS_BUCKET=$1

# zip and upload lambda scripts to s3 and output version to varName
update_lambda() {
  local lambda_filename=$1
  local varName=$2
  local version_id
  echo "zipping and uploading scripts/lambda/${lambda_filename} to S3..."
  # Create a temporary directory to store the Lambda script's zip file
  LAMBDA_DIR=$(mktemp -d)
  cp "scripts/lambda/${lambda_filename}" "$LAMBDA_DIR"
  cd "$LAMBDA_DIR"
  # Zip the Lambda script
  zip "${lambda_filename%.py}.zip" "${lambda_filename}"
  cd -
  # Upload the zip file to S3
  aws s3 cp "${LAMBDA_DIR}/${lambda_filename%.py}.zip" "s3://${SCRIPTS_BUCKET}/lambda/${lambda_filename%.py}.zip"
  # Remove the temporary directory
  rm -r "$LAMBDA_DIR"
  # Get the latest version ID of the uploaded file in S3
  version_id=$(aws s3api list-object-versions --bucket "$SCRIPTS_BUCKET" --prefix "lambda/${lambda_filename%.py}.zip" --query 'Versions[?IsLatest].VersionId' --output text)
  # Append the version ID to the GitHub environment file
  echo "$varName=$version_id" >> $GITHUB_ENV
}

# Upload CloudFormation templates to S3
echo "Uploading CloudFormation templates to S3..."
aws s3 sync cloudformation/ s3://${SCRIPTS_BUCKET}/cloudformation/

# upload gluejob scripts
echo "Uploading Glue scripts to S3..."
aws s3 sync scripts/gluejob/ s3://${SCRIPTS_BUCKET}/gluejob/

# update lambda raw2staging
update_lambda raw2staging.py LAMBDA_RAW2STAGING_VERSION

echo "All files uploaded successfully."

