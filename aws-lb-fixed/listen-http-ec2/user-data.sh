#!/bin/bash
# shellcheck disable=SC2154
set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# The variables below are filled in using Terraform interpolation
echo "${instance_text}" > index.html
nohup busybox httpd -f -p "${instance_port}" &
