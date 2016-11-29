#!/bin/sh

set -eu -o pipefail

cd working-tree

source ci/bin/target-bosh-director ../bosh-director

bosh upload-release ../bosh-release/*.tgz
bosh upload-stemcell ../bosh-stemcell/*.tgz

export BOSH_DEPLOYMENT=subject

bosh -n deploy ci/tasks/integration-test/deployment.yml

bosh run-errand make-bucket

bosh run-errand mirror-push

bosh ssh -c 'sudo /var/vcap/jobs/mc-mirror/bin/run' mirror-pull/0

bosh ssh -c \
  '
    sudo find /var/vcap/data/mirror-pull -type f \
      | tee /dev/stderr \
      | grep -q /var/vcap/data/mirror-pull
  ' \
  mirror-pull/0
