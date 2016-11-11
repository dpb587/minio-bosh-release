# minio-bosh-release

A S3-compatible object storage server backed by [minio](https://www.minio.io/).


## Usage

Configure a [`minio`](jobs/minio/spec) job with at least `access_key` and `secret_key`...

    jobs:
      - name: "minio"
        release: "minio"
        properties:
          scheme: "http"
          access_key: "aDifferentAccessKey"
          secret_key: "aDifferentSecretKey"

A browser UI is accessible on port 9000. You can use any S3-compatible client such as [mc](https://docs.minio.io/docs/minio-client-quickstart-guide),  [s3cmd](https://docs.minio.io/docs/s3cmd-with-minio), [awscli](https://docs.minio.io/docs/aws-cli-with-minio), and [Cyberduck](https://docs.minio.io/docs/how-to-use-cyberduck-with-minio). Objects are stored in `/var/vcap/store/minio`.

Additional, errand-oriented jobs are...

 * [`mc-mb`](jobs/mc-mb/spec) - for creating a bucket (primarily used for testing)
 * [`mc-mirror`](jobs/mc-mirror/spec) - for mirroring a local directory to/from a remote endpoint

A sample [bosh-lite](https://github.com/cloudfoundry/bosh-lite) manifest is at [`src/bosh-lite/manifest.yml`](src/bosh-lite/manifest.yml).


## Links

Jobs in this release provide and consume [links](http://bosh.io/docs/links.html).


### `s3` (`storage`)

The `minio` job *provides* a link of type `s3`. Another job template might consume it with...

    # <% s3 = link('s3') %>
    $ mc config host add s3 \
      "<%= s3.p('scheme') %>://<%= s3.instances[0].address %>:<%= s3.p('port') %>" \
      "<%= s3.p('access_key_id') %>" \
      "<%= s3.p('secret_access_key') %>"

    $  mc cp backup.tar.gz "s3/<%= p('bucket') %>/backup.tar.gz"

The `mc-*` job *consumes* a link of type `s3` named `storage`. Ensure a link is provided from a [job](http://bosh.io/docs/links.html#implicit), [deployment](http://bosh.io/docs/links.html#deployment), or [manually](http://bosh.io/docs/links-manual.html)...

    jobs:
      - name: "mc-mirror"
        release: "minio"
        consumes:
          storage:
            instances:
              - address: "s3.amazonaws.com"
            properties:
              access_key: "AKIA01234567890"
              api: "S3v4"
              port: 443
              scheme: "https"
              secret_key: "a1b2c3d4e5f6g7h"


## License

[MIT License](./LICENSE)
