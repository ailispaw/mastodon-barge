FROM ruby:2.4.1-alpine

LABEL maintainer="https://github.com/ailispaw/mastodon" \
      description="A GNU Social-compatible microblogging server"

EXPOSE 3000 4000

RUN echo "@edge https://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
 && apk --no-cache --update add \
      ca-certificates \
      ffmpeg \
      file \
      git \
      imagemagick@edge \
      libpq \
      libxml2 \
      libxslt \
      nodejs-npm@edge \
      nodejs@edge \
      protobuf \
      tini \
    \
 && npm install -g yarn \
 && update-ca-certificates \
    \
 && npm -g cache clean \
 && rm -rf /tmp/* /var/cache/apk/*

ENV MASTODON_VERSION=1.4.1 \
    UID=1000 GID=1000 \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production

RUN apk --no-cache --update add --virtual build-deps \
      build-base \
      curl \
      libxml2-dev \
      libxslt-dev \
      postgresql-dev \
      protobuf-dev \
      python \
    \
 && curl -sL https://github.com/tootsuite/mastodon/archive/v${MASTODON_VERSION}.tar.gz | tar xz -C / \
 && mv /mastodon-${MASTODON_VERSION} /mastodon \
 && cd /mastodon \
 && rm -rf .env.* storybook \
    \
 && bundle install --deployment --without test development \
 && yarn --ignore-optional --pure-lockfile \
    \
 && yarn cache clean \
 && bundle clean \
 && npm -g cache clean \
 && apk del build-deps \
 && rm -rf /root/.bundle /root/.gem /root/.node-gyp /root/.npm \
 && rm -rf /tmp/* /var/cache/apk/* \
    \
 && addgroup -g ${GID} mastodon \
 && adduser -h /mastodon -s /bin/sh -D -G mastodon -u ${UID} mastodon \
 && chown -R mastodon:mastodon .

VOLUME /mastodon/public/system /mastodon/public/assets /mastodon/public/packs

USER mastodon

WORKDIR /mastodon

ENTRYPOINT [ "/sbin/tini", "--" ]
