#
# Copyright (c) 2018-2021 IOTech Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ARG BASE=golang:1.18-alpine3.16
FROM ${BASE} AS builder

ARG ADD_BUILD_TAGS=""
ARG MAKE="make -e ADD_BUILD_TAGS=$ADD_BUILD_TAGS build"

ARG ALPINE_PKG_BASE="make git openssh-client"
ARG ALPINE_PKG_EXTRA=""

RUN apk add --update --no-cache ${ALPINE_PKG_BASE} ${ALPINE_PKG_EXTRA}

WORKDIR /device-snmp-go

COPY go.mod vendor* ./
RUN [ ! -d "vendor" ] && go mod download all || echo "skipping..."

COPY . .
RUN ${MAKE}

FROM alpine:3.16

# dumb-init needed for injected secure bootstrapping entrypoint script when run in secure mode.
RUN apk add --update --no-cache dumb-init

COPY --from=builder /device-snmp-go/cmd /
COPY --from=builder /device-snmp-go/Attribution.txt /
COPY --from=builder /device-snmp-go/LICENSE /

EXPOSE 59993
EXPOSE 161

ENTRYPOINT ["/device-snmp"]
CMD ["--cp=consul.http://edgex-core-consul:8500", "--registry"]
