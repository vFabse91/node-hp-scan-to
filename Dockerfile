FROM node:alpine as build
WORKDIR /app

ADD . .
RUN yarn install -d \
 && yarn build \
 && rm dist/*.d.ts dist/*.js.map

FROM node:alpine as app
ENV NODE_ENV production
ADD root/ /

# add S6 Overlay
ADD https://github.com/just-containers/s6-overlay/releases/latest/download/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-armhf.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-armhf.tar.gz -C /

# install shadow (for groupmod and usermod) and tzdata (for TZ env variable)
RUN apk add --no-cache shadow tzdata

# add builded app
WORKDIR /app
COPY --from=build /app/dist/ /app/package.json ./
RUN yarn install -d \
 && yarn cache clean --force

VOLUME ["/scan"]
ENTRYPOINT ["/init"]
CMD ["/app.sh"]
