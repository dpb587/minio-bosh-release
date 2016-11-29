FROM alpine:3.4
RUN true \
  && apk --no-cache add bash build-base ca-certificates curl git openssl openssl-dev ruby ruby-dev openssh zlib-dev \
  && gem install --no-doc json \
  && curl -Lo /usr/local/bin/bosh https://s3.amazonaws.com/bosh-cli-artifacts/bosh-cli-0.0.122-linux-amd64 && chmod +x /usr/local/bin/bosh \
  && curl -Lo /usr/local/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x /usr/local/bin/jq
