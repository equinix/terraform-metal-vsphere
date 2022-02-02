#!/bin/bash

SSH_PRIVATE_KEY='${ssh_private_key}'

object_store_tool=`echo "${object_store_tool}" | awk '{print tolower($0)}'`

# TODO: This should probably not be hidden in the download_vcenter.sh
cat <<EOF >/$HOME/.ssh/esxi_key
$SSH_PRIVATE_KEY
EOF
chmod 0400 /$HOME/.ssh/esxi_key
# END TODO
echo "Set SSH config to not do StrictHostKeyChecking"
cat <<EOF >/$HOME/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
chmod 0400 /$HOME/.ssh/config

BASE_DIR="/$HOME/bootstrap"

mkdir -p $BASE_DIR
cd $BASE_DIR
if [ $object_store_tool = "gcs" ]; then
  echo "USING GCS"
  gcloud auth activate-service-account --key-file=$HOME/bootstrap/gcp_storage_reader.json
  gsutil cp gs://${object_store_bucket_name}/${vcenter_iso_name} .
  gsutil cp gs://${object_store_bucket_name}/vsanapiutils.py .
  gsutil cp gs://${object_store_bucket_name}/vsanmgmtObjects.py .
elif [ $object_store_tool = "mc" ]; then
  echo "USING S3"
  curl -Lo mc https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2022-01-07T06-01-38Z
  echo -n '33d25b2242626d1e07ce7341a9ecc2164c0ef5c0  mc' | shasum -a1 -c - && chmod +x mc
  mv mc /usr/local/bin/
  mc config host add s3 ${s3_url} ${s3_access_key} ${s3_secret_key}
  mc cp s3/${object_store_bucket_name}/${vcenter_iso_name} .
  mc cp s3/${object_store_bucket_name}/vsanapiutils.py .
  mc cp s3/${object_store_bucket_name}/vsanmgmtObjects.py .
else
  echo "Only gcs & mc are supported for object_store_tool at this point."
  exit 1
fi
mount $BASE_DIR/${vcenter_iso_name} /mnt/
