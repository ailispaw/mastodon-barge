FROM ruby:2.4.1-alpine

LABEL maintainer="https://github.com/ailispaw/mastodon" \
      description="A GNU Social-compatible microblogging server"

ENV RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production

EXPOSE 3000 4000

WORKDIR /mastodon

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
 && rm -rf /tmp/* /var/cache/apk/*

COPY Gemfile Gemfile.lock package.json yarn.lock /mastodon/

RUN apk --no-cache --update add --virtual build-deps \
      build-base \
      libxml2-dev \
      libxslt-dev \
      postgresql-dev \
      protobuf-dev \
      python \
 && npm install -g yarn \
 && update-ca-certificates \
 && bundle install --deployment --without test development \
 && yarn --ignore-optional --pure-lockfile \
 && yarn cache clean \
 && npm -g cache clean \
 && apk del build-deps \
 && rm -rf /root/.bundle /root/.gem /root/.node-gyp \
 && rm -rf /tmp/* /var/cache/apk/*

COPY . /mastodon

ENV UID=1000 GID=1000

RUN addgroup -g ${GID} mastodon \
 && adduser -h /mastodon -s /bin/sh -D -G mastodon -u ${UID} mastodon \
 && chown -R mastodon:mastodon /mastodon

VOLUME /mastodon/public/system /mastodon/public/assets /mastodon/public/packs

USER mastodon

ENTRYPOINT [ "/sbin/tini", "--" ]
