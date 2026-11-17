# Copyright 2026 Han Li and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Repository dev container: the Linux userland the local checks and E2E suites
# need. The suites talk to the host Docker daemon through the socket mounted by
# devcontainer.json, so they spawn target containers the same way CI does.
FROM golang:1.27.1

COPY --from=docker:29-cli /usr/local/bin/docker /usr/local/bin/docker

ARG STYLUA_VERSION=2.5.2
ARG LUALS_VERSION=3.19.1
ARG VFOX_VERSION=1.1.0

RUN <<EOF
set -o errexit -o nounset -o xtrace
apt-get update
apt-get install --assume-yes --no-install-recommends ca-certificates curl unzip zip
rm --recursive --force /var/lib/apt/lists/*
case "$(dpkg --print-architecture)" in
    amd64) stylua_asset=stylua-linux-x86_64.zip; luals_asset="lua-language-server-${LUALS_VERSION}-linux-x64.tar.gz"; vfox_dir="vfox_${VFOX_VERSION}_linux_x86_64" ;;
    arm64) stylua_asset=stylua-linux-aarch64.zip; luals_asset="lua-language-server-${LUALS_VERSION}-linux-arm64.tar.gz"; vfox_dir="vfox_${VFOX_VERSION}_linux_aarch64" ;;
    *) echo "FAIL unsupported architecture" >&2; exit 1 ;;
esac
curl --fail --silent --show-error --location --output /tmp/stylua.zip \
    "https://github.com/JohnnyMorganz/StyLua/releases/download/v${STYLUA_VERSION}/${stylua_asset}"
unzip -q /tmp/stylua.zip -d /usr/local/bin
curl --fail --silent --show-error --location --output /tmp/luals.tar.gz \
    "https://github.com/LuaLS/lua-language-server/releases/download/${LUALS_VERSION}/${luals_asset}"
mkdir --parents /opt/lua-language-server
tar --extract --gzip --file /tmp/luals.tar.gz --directory /opt/lua-language-server
ln --symbolic /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
curl --fail --silent --show-error --location --output /tmp/vfox.tar.gz \
    "https://github.com/version-fox/vfox/releases/download/v${VFOX_VERSION}/${vfox_dir}.tar.gz"
tar --extract --gzip --file /tmp/vfox.tar.gz --directory /usr/local/bin --strip-components=1 "${vfox_dir}/vfox"
rm --force /tmp/stylua.zip /tmp/luals.tar.gz /tmp/vfox.tar.gz
GOBIN=/usr/local/bin go install github.com/apache/skywalking-eyes/cmd/license-eye@v0.9.0
GOBIN=/usr/local/bin go install github.com/rhysd/actionlint/cmd/actionlint@v1.7.7
stylua --version
lua-language-server --version
vfox --version
EOF
