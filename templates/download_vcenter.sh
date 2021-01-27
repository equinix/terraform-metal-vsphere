#!/bin/bash

SSH_PRIVATE_KEY='${ssh_private_key}'

s3_boolean=`echo "${s3_boolean}" | awk '{print tolower($0)}'`
cd /root/anthos

# TODO: This should probably not be hidden in the download_vcenter.sh
cat <<EOF >/$HOME/.ssh/esxi_key
$SSH_PRIVATE_KEY
EOF
chmod 0400 /$HOME/.ssh/esxi_key
# END TODO
echo "Set SSH config to not do StrictHostKeyChecking"
cat <<EOF >/root/.ssh/config
Host *
    StrictHostKeyChecking no
EOF
chmod 0400 /$HOME/.ssh/config

mkdir -p /$HOME/bootstrap/
cd /root/
if [ $s3_boolean = "false" ]; then
  echo "USING GCS"
  # Install Apt Packages
  echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main' > /etc/apt/sources.list.d/google-cloud-sdk.list
  # TODO: Using Apt here could come bite us bad if another process is using apt...
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
  DEBIAN_FRONTEND=noninteractive apt-get update -y
  DEBIAN_FRONTEND=noninteractive apt-get install -o Dpkg::Options::="--force-confold" --force-yes -y google-cloud-sdk
  gcloud auth activate-service-account --key-file=$HOME/anthos/gcp_keys/${storage_reader_key_name}
  gsutil cp gs://${gcs_bucket_name}/${vcenter_iso_name} .
  gsutil cp gs://${gcs_bucket_name}/vsanapiutils.py .
  gsutil cp gs://${gcs_bucket_name}/vsanmgmtObjects.py .
else
  echo "USING S3"
  curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc
  chmod +x mc
  mv mc /usr/local/bin/
  mc config host add s3 ${s3_url} ${s3_access_key} ${s3_secret_key}
  mc cp s3/${s3_bucket_name}/${vcenter_iso_name} .
  mc cp s3/${s3_bucket_name}/vsanapiutils.py .
  mc cp s3/${s3_bucket_name}/vsanmgmtObjects.py .
fi
mount /root/${vcenter_iso_name} /mnt/
