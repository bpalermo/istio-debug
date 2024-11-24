ARG ISTIO_VERSION=1.22.6
ARG BASE_IMAGE_TAG=1.22-2024-09-17T19-00-54
FROM registry.hub.docker.com/istio/base:${BASE_IMAGE_TAG} AS runtime

RUN apt-get update && \
    apt-get install -qqy \
    golang \
    graphviz \
    linux-tools-generic \
    && rm -rf /var/lib/apt/lists/*

RUN go install github.com/google/pprof@latest \
    && export PATH=$PATH:$(go env GOPATH)/bin

FROM runtime AS src
ARG ISTIO_VERSION

RUN apt-get update && \
    apt-get install -qqy \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone --depth 1 -b ${ISTIO_VERSION} https://github.com/istio/tools.git \
    && git clone --depth 1 -b master https://github.com/brendangregg/FlameGraph.git

FROM runtime

COPY --from=src /src/tools/perf/benchmark/flame/get_perfdata.sh /etc/istio/proxy/get_perfdata.sh
COPY --from=src /src/tools/perf/benchmark/flame/flame.sh /etc/istio/proxy/flame.sh
COPY --from=src /src/FlameGraph /etc/istio/proxy/
