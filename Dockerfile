FROM ruby:2.4.2-alpine3.6

LABEL maintainer="https://github.com/ailispaw/mastodon-barge" \
      description="A GNU Social-compatible microblogging server"

EXPOSE 3000 4000

RUN apk -U upgrade \
 && apk --no-cache --update add \
      ca-certificates \
      ffmpeg \
      file \
      git \
      icu-libs \
      imagemagick \
      libidn \
      libpq \
      nodejs \
      nodejs-npm \
      protobuf \
      tini \
    \
 && update-ca-certificates \
    \
 && rm -rf /tmp/* /var/cache/apk/*

ENV MASTODON_VERSION=2.1.0 \
    UID=1000 GID=1000 \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production \
    YARN_VERSION=1.3.2 \
    YARN_DOWNLOAD_SHA256=6cfe82e530ef0837212f13e45c1565ba53f5199eec2527b85ecbcd88bf26821d \
    LIBICONV_VERSION=1.15 \
    LIBICONV_DOWNLOAD_SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

RUN apk --no-cache --update add --virtual build-deps \
      build-base \
      curl \
      icu-dev \
      libidn-dev \
      libressl \
      libtool \
      postgresql-dev \
      protobuf-dev \
      python \
      su-exec \
    \
 && mkdir -p /tmp/src /opt \
 && wget -O yarn.tar.gz "https://github.com/yarnpkg/yarn/releases/download/v$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
 && echo "$YARN_DOWNLOAD_SHA256 *yarn.tar.gz" | sha256sum -c - \
 && tar -xzf yarn.tar.gz -C /tmp/src \
 && rm yarn.tar.gz \
 && mv /tmp/src/yarn-v$YARN_VERSION /opt/yarn \
 && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
 && wget -O libiconv.tar.gz https://ftp.gnu.org/pub/gnu/libiconv/libiconv-${LIBICONV_VERSION}.tar.gz \
 && echo "${LIBICONV_DOWNLOAD_SHA256} *libiconv.tar.gz" | sha256sum -c - \
 && tar -xzf libiconv.tar.gz -C /tmp/src \
 && rm libiconv.tar.gz \
 && cd /tmp/src/libiconv-${LIBICONV_VERSION} \
 && ./configure --prefix=/usr/local \
 && make -j$(getconf _NPROCESSORS_ONLN) \
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
 && su-exec mastodon:mastodon bundle install -j$(getconf _NPROCESSORS_ONLN) --deployment --without test development \
 && su-exec mastodon:mastodon yarn --pure-lockfile \
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
