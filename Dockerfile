#syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.6.1 AS xx

FROM --platform=$BUILDPLATFORM golang:1.26.10-alpine3.24@sha256:2173d702003b1a8d17b844191acaeb36e94de46f6cabf2cb27370e151bbce5aa AS build
WORKDIR /app

COPY --from=xx / /

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go generate -x ./...

ARG TARGETPLATFORM
RUN --mount=type=cache,target=/root/.cache \
  CGO_ENABLED=0 xx-go build -ldflags='-w -s' -trimpath -tags gzip


FROM alpine:3.24.4@sha256:0f49f331d9212aff11b932863be4eb01cdf962969aa86dab7d1ee21ac6f5f52b

RUN apk upgrade --no-cache && apk add --no-cache tzdata

ARG USERNAME=ascii-movie
ARG UID=1000
ARG GID=$UID
RUN addgroup -g "$GID" "$USERNAME" \
    && adduser -S -u "$UID" -G "$USERNAME" "$USERNAME"

COPY --from=build /app/ascii-movie /bin
ENV TERM=xterm-256color
ENV ASCII_MOVIE_SSH_ENABLED=false
ENV ASCII_MOVIE_SSH_HOST_KEY=""
VOLUME /data
USER $UID
ENTRYPOINT ["ascii-movie"]
CMD ["serve"]
