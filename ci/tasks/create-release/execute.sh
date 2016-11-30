#!/bin/sh

set -eu -o pipefail

task_dir=$PWD
version=$( cat version/number )

git clone file://$task_dir/downloads downloads-output

cd working-tree


#
# create the release
#

bosh create-release \
  --version="$version" \
  --tarball

cp releases/*/*.tgz $task_dir/bosh-release/

#
# download reference
#

path=$( echo $task_dir/bosh-release/*.tgz )

jq -n \
  --arg version "$version" \
  --arg download_prefix "$download_prefix" \
  --arg name "$( basename "$path" )" \
  '
    {
      "metadata": [
        {
          "key": "stability",
          "value": "dev",
        },
        {
          "key": "type",
          "value": "bosh-source-release"
        },
        {
          "key": "version",
          "value": $version
        }
      ],
      "origin": [
        {
          "uri": "\($download_prefix)\($name)"
        }
      ]
    }
  ' \
  | ./ci/bin/commit-download "$path" "$task_dir/downloads-output"
