FROM node:8.11.3-alpine as node
FROM ruby:2.4.4-alpine3.6

LABEL maintainer="https://github.com/ailispaw/mastodon-barge" \
      description="Your self-hosted, globally interconnected microblogging community"

EXPOSE 3000 4000

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node /opt/yarn-* /opt/yarn

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
      protobuf \
      tini \
      tzdata \
    \
 && update-ca-certificates \
    \
 && rm -rf /tmp/* /var/cache/apk/*

ENV MASTODON_VERSION=2.5.0 \
    UID=1000 GID=1000 \
    PATH=/mastodon/bin:$PATH \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production \
    LIBICONV_VERSION=1.15 \
    LIBICONV_DOWNLOAD_SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

# Apply patches
COPY patches /patches

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
      patch \
    \
 && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
 && ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg \
 && mkdir -p /tmp/src /opt \
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
 && for patch in /patches/*.patch; do \
      patch -p1 -d /mastodon < ${patch}; \
    done \
 && rm -rf .env.* storybook \
    \
 && addgroup -g ${GID} mastodon \
 && adduser -h /mastodon -s /bin/sh -D -G mastodon -u ${UID} mastodon \
 && chown -R mastodon:mastodon . \
    \
 && su-exec mastodon:mastodon bundle config build.nokogiri --with-iconv-lib=/usr/local/lib --with-iconv-include=/usr/local/include \
 && su-exec mastodon:mastodon bundle install -j$(getconf _NPROCESSORS_ONLN) --deployment --without test development \
 && su-exec mastodon:mastodon yarn install --pure-lockfile --ignore-engines \
    \
 && su-exec mastodon:mastodon yarn cache clean \
 && su-exec mastodon:mastodon bundle clean \
 && su-exec mastodon:mastodon rm -rf .bundle .cache .node-gyp \
    \
 && apk del build-deps \
 && rm -rf /tmp/* /var/cache/apk/*

VOLUME /mastodon/public/system

USER mastodon

WORKDIR /mastodon

RUN OTP_SECRET=precompile_placeholder SECRET_KEY_BASE=precompile_placeholder bundle exec rails assets:precompile

ENTRYPOINT [ "/sbin/tini", "--" ]
