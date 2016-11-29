#!/bin/sh

set -eu -o pipefail

task_dir=$PWD

cd bosh-director

mkdir .bosh
ln -s $PWD/.bosh ~/.bosh

echo "$iaas_config" > vars.yml

bosh interpolate \
  --ops-file ../bosh-deployment/aws/cpi.yml \
  --ops-file ../working-tree/ci/tasks/create-bosh-director/manifest-ops.yml \
  ../bosh-deployment/bosh.yml \
  > manifest.yml

bosh create-env \
  --vars-store vars.yml \
  --state state.json \
  manifest.yml

bosh interpolate --path /director_ssl/ca vars.yml > ca.crt
bosh interpolate --path /internal_ip vars.yml > ip
echo admin > username
bosh interpolate --path /admin_password vars.yml > password

source ../working-tree/ci/bin/target-bosh-director

bosh -n update-cloud-config \
  --ops-file ../working-tree/ci/tasks/create-bosh-director/cloud-config-ops.yml \
  --vars-store vars.yml \
  ../bosh-deployment/aws/cloud-config.yml
