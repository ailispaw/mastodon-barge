FROM ruby:2.4.1-alpine

LABEL maintainer="https://github.com/ailispaw/mastodon" \
      description="A GNU Social-compatible microblogging server"

EXPOSE 3000 4000

RUN echo "@edge https://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
 && echo "@edge https://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
 && apk -U upgrade \
 && apk --no-cache --update add \
      ca-certificates \
      ffmpeg \
      file \
      git \
      icu-libs \
      imagemagick@edge \
      libidn \
      libpq \
      nodejs-npm@edge \
      nodejs@edge \
      protobuf \
      tini \
      yarn@edge \
    \
 && update-ca-certificates \
    \
 && rm -rf /tmp/* /var/cache/apk/*

ENV MASTODON_VERSION=1.5.1 \
    UID=1000 GID=1000 \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production \
    LIBICONV_VERSION=1.15 \
    LIBICONV_DOWNLOAD_SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

RUN apk --no-cache --update add --virtual build-deps \
      build-base \
      curl \
      icu-dev \
      libidn-dev \
      libtool \
      postgresql-dev \
      protobuf-dev \
      python \
      su-exec \
    \
 && wget -O libiconv.tar.gz http://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz \
 && echo "${LIBICONV_DOWNLOAD_SHA256} *libiconv.tar.gz" | sha256sum -c - \
 && mkdir -p /tmp/src \
 && tar -xzf libiconv.tar.gz -C /tmp/src \
 && rm libiconv.tar.gz \
 && cd /tmp/src/libiconv-${LIBICONV_VERSION} \
 && ./configure --prefix=/usr/local \
 && make \
 && make install \
 && libtool --finish /usr/local/lib \
    \
 && curl -sL https://github.com/tootsuite/mastodon/archive/v${MASTODON_VERSION}.tar.gz | tar xz -C / \
 && mv /mastodon-${MASTODON_VERSION} /mastodon \
 && cd /mastodon \
 && rm -rf .env.* storybook \
    \
 && addgroup -g ${GID} mastodon \
 && adduser -h /mastodon -s /bin/sh -D -G mastodon -u ${UID} mastodon \
 && chown -R mastodon:mastodon . \
    \
 && su-exec mastodon:mastodon bundle install --deployment --without test development \
 && su-exec mastodon:mastodon yarn --ignore-optional --pure-lockfile \
    \
 && su-exec mastodon:mastodon yarn cache clean \
 && su-exec mastodon:mastodon bundle clean \
 && su-exec mastodon:mastodon npm -g cache clean \
 && su-exec mastodon:mastodon rm -rf .bundle .cache .node-gyp \
    \
 && apk del build-deps \
 && rm -rf /tmp/* /var/cache/apk/*

VOLUME /mastodon/public/system /mastodon/public/assets /mastodon/public/packs

USER mastodon

WORKDIR /mastodon

ENTRYPOINT [ "/sbin/tini", "--" ]
