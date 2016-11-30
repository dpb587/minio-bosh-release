#!/bin/sh

set -eu -o pipefail

task_dir=$PWD
version=$( cat version/number )

git config --global user.email "${git_user_email:-ci@localhost}"
git config --global user.name "${git_user_name:-CI Bot}"
export GIT_COMMITTER_NAME="Concourse"
export GIT_COMMITTER_EMAIL="concourse.ci@localhost"

git clone file://$task_dir/final-working-tree updated-final-working-tree
git clone file://$task_dir/dev-working-tree updated-dev-working-tree
git clone file://$task_dir/downloads downloads-output

cd working-tree/


#
# we'll be updating the blobstore
#

cat > config/private.yml <<EOF
---
blobstore:
  options:
    access_key_id: "$blobstore_access_key"
    secret_access_key: "$blobstore_secret_key"
EOF


#
# finalize the release
#

bosh finalize-release \
  $task_dir/dev-bosh-release-tarball/*.tgz \
  --version="$version"


#
# commit final release
#

git add -A .final_builds releases

(
  echo "Release v$version"
  [ ! -e releases/*/*-$version.md ] || ( echo "" ; cat releases/*/*-$version.md )
) \
  | git commit -F-

git checkout -b release


#
# official release tarball
#

bosh create-release \
  --version="$version" \
  --tarball

cp releases/*/*.tgz $task_dir/bosh-release-tarball/


#
# download reference
#

path=$( echo $task_dir/bosh-release-tarball/*.tgz )


jq -n \
  --arg version "$version" \
  --arg download_prefix "$download_prefix" \
  --arg name "$( basename "$path" )" \
  '
    {
      "metadata": [
        {
          "key": "stability",
          "value": "stable",
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


#
# release artifacts
#

echo "v$version" > $task_dir/release/tag
git rev-parse HEAD > $task_dir/release/commit

if [ -e releases/*/*-$version.md ] ; then
  cp releases/*/*-$version.md $task_dir/release/notes.md
else
  touch $task_dir/release/notes.md
fi


#
# merge release to final
#

cd $task_dir/updated-final-working-tree

git remote add --fetch \
  working-tree \
  file://$task_dir/working-tree

final_branch=$( git rev-parse --abbrev-ref HEAD )

git merge --no-ff \
  -m "$( echo "Merge branch 'release-$version' into $final_branch" )" \
  working-tree/release


#
# merge final to master
#

cd $task_dir/updated-dev-working-tree

git remote add --fetch \
  updated-final-working-tree \
  file://$task_dir/updated-final-working-tree

master_branch=$( git rev-parse --abbrev-ref HEAD )

git merge --no-ff \
  -m "Merge branch '$final_branch' into $master_branch" \
  updated-final-working-tree/$final_branch
