FROM registry.hub.docker.com/amazonlinux:2 AS base-runtime
ARG TARGETARCH

RUN apt-get update && \
    apt-get install -y \
    golang \
    graphviz \
    linux-tools-generic \
    && rm -rf /var/lib/apt/lists/*

RUN go install github.com/google/pprof@latest

FROM base-runtime AS base
ARG TARGETARCH

RUN yum update && \
    yum install -y \
    g++ \
    git \
    libcap-dev \
    libelf-dev \
    && yum -y clean all \
    && rm -fr /var/cache 

RUN go install github.com/bazelbuild/bazelisk@latest

WORKDIR /src

RUN git clone --depth 1 -b master https://github.com/google/perf_data_converter.git

FROM base AS build

WORKDIR /src/perf_data_converter

RUN bazel build src:perf_to_profile

FROM base-runtime

COPY --from=build /src/perf_data_converter/bazel-bin/src/perf_to_profile /usr/local/bin/
