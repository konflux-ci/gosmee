# Hermetic Konflux build of chmouel/gosmee.
# The gosmee/ directory is the upstream submodule. Upstream vendors its
# dependencies (gosmee/vendor/), so the build reads straight from vendor/
# with no network or module cache needed at all.

ARG GOSMEE_VERSION=v0.32.1

FROM registry.access.redhat.com/ubi10/go-toolset@sha256:78049192391115cdcc3a794bf0e7295a1f54fbb110c0a832e6b1254dbd15239d AS builder

ARG GOSMEE_VERSION
ARG TARGETARCH

WORKDIR /workspace/gosmee

COPY --chown=1001:0 gosmee/ ./
# Upstream release builds stamp this embedded file. The submodule copy says "dev".
RUN printf '%s' "${GOSMEE_VERSION}" > gosmee/templates/version

RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    GOFLAGS="-buildvcs=false" go build -mod=vendor -trimpath \
    -ldflags="-s -w" -o /tmp/gosmee .

FROM registry.access.redhat.com/ubi10/ubi-micro@sha256:09d42b63a4ef2a23543502bd09e892c495a4ca480d481e28f00b3070d62d2d24

ARG GOSMEE_VERSION

COPY --from=builder /tmp/gosmee /usr/local/bin/gosmee
COPY --from=builder /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt

LABEL description="gosmee relays webhook deliveries between a public server and a private client."
LABEL distribution-scope="public"
LABEL com.redhat.component="gosmee"
LABEL io.k8s.description="gosmee relays webhook deliveries between a public server and a private client."
LABEL name="gosmee"
LABEL release="1"
LABEL url="https://github.com/chmouel/gosmee"
LABEL vendor="Red Hat, Inc."
LABEL version="${GOSMEE_VERSION}"
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.description="gosmee relays webhook deliveries between a public server and a private client." \
      org.opencontainers.image.documentation="https://github.com/chmouel/gosmee" \
      org.opencontainers.image.source="https://github.com/chmouel/gosmee" \
      org.opencontainers.image.title="gosmee" \
      org.opencontainers.image.vendor="Red Hat, Inc." \
      org.opencontainers.image.version="${GOSMEE_VERSION}"

USER 1001
ENTRYPOINT ["/usr/local/bin/gosmee"]
