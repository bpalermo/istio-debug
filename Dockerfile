ARG BASE_VERSION="1.22-2024-09-17T19-00-54"
ARG BAZELISK_VERSION="v1.24.0"
FROM registry.hub.docker.com/istio/base:${BASE_VERSION} AS base-runtime
ARG BAZELISK_VERSION
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y \
    golang \
    linux-tools-generic \
    && rm -rf /var/lib/apt/lists/*

RUN https://go.dev/dl/

FROM base-runtime AS base
ARG BAZELISK_VERSION
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y \
    g++ \
    git \
    libcap-dev \
    libelf-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl -Lso bazelisk https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-${TARGETARCH} \
    && chmod 755 bazelisk \
    && mv bazelisk /usr/local/bin/bazelisk \
    && ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

WORKDIR /src

RUN git clone --depth 1 -b master https://github.com/google/perf_data_converter.git

FROM base AS build

WORKDIR /src/perf_data_converter

RUN bazel build src:perf_to_profile

FROM base-runtime

COPY --from=build /src/perf_data_converter/bazel-bin/src/perf_to_profile /usr/local/bin/
