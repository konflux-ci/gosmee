# Hermetic Konflux build of chmouel/gosmee.
# The gosmee/ directory is the upstream submodule. Upstream vendors its
# dependencies (gosmee/vendor/), so the build reads straight from vendor/
# with no network or module cache needed at all.

ARG GOSMEE_VERSION=v0.32.1

FROM registry.access.redhat.com/ubi10/go-toolset@sha256:05619897582acb01ee5dd3eaa2934a7cc2f24409a255142a704b734ef07b68a6 AS builder

ARG GOSMEE_VERSION
ARG TARGETARCH

WORKDIR /workspace/gosmee

COPY --chown=1001:0 gosmee/ ./
# Upstream release builds stamp this embedded file. The submodule copy says "dev".
RUN printf '%s' "${GOSMEE_VERSION}" > gosmee/templates/version

RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} \
    GOFLAGS="-buildvcs=false" go build -mod=vendor -trimpath \
    -ldflags="-s -w" -o /tmp/gosmee .

# ubi-micro omits grep/awk entirely, which breaks the smee-sidecar liveness
# probe (check-smee-health.sh) deterministically. ubi-minimal keeps the same
# hermeticity (binary is still built in the separate go-toolset stage above).
FROM registry.access.redhat.com/ubi10/ubi-minimal@sha256:c039ecb9ac9db2db85e78b332d66521f6ce401cf812006a27bc7827018eac4a2

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
