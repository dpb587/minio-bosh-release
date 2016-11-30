#!/bin/sh

set -eu -o pipefail

task_dir=$PWD

cd bosh-director

[ -e ip ] || exit 0

ln -s $PWD/.bosh ~/.bosh

source ../working-tree/ci/bin/target-bosh-director

bosh deployments | cut -f1 | ( grep -vE '^ +$' || true ) | xargs -rn1 \
  bosh -n delete-deployment -d

bosh -n clean-up --all

bosh delete-env \
  --vars-file vars.yml \
  --state state.json \
  manifest.yml
