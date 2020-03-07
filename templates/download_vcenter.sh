#!/bin/bash
cd /root/
curl -LO https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin/
mc config host add s3 ${s3_url} ${s3_access_key} ${s3_secret_key}
mc cp s3/${s3_bucket_name}/${vcenter_iso_name} .
mc cp s3/${s3_bucket_name}/vsanapiutils.py .
mc cp s3/${s3_bucket_name}/vsanmgmtObjects.py .

mount /root/${vcenter_iso_name} /mnt/
