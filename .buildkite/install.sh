#!/usr/bin/env bash

BUILDKITE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$( cd "$BUILDKITE_DIR/.." && pwd )"
BIN_DIR="$BASE_DIR/bin"

# Load lib functions
lib_functions="$BIN_DIR/functions"
echo "Using version: ${SCRIPTS_VERSION:-stable}"
curl -Ls -o "${lib_functions}" "https://s3.amazonaws.com/bit-ops-artifacts/scripts/lib/${SCRIPTS_VERSION:-stable}/functions"
source "${lib_functions}"

install_dir="/opt"
version="$(buildkite-agent meta-data get release-name)"
test -n "${version}" || { error "Unable to read the Buildkite meta-data 'release-name'." ; exit 1;}
url="https://github.com/bandsintown/gaia/archive/${version}.tar.gz"
curl_options="-Ls --connect-timeout 10 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 60"

cd "$install_dir"

info "Installing Gaia on Buildkite server..."
mkdir -p "gaia-${version}"
response=$(curl -Ls "${url}" | tar xz)

if [ $? -ne 0 ]; then
  error "Error installing Gaia on Buildkite server:"
  error "$response"
fi

success "Gaia $version installed on Buildkite server !"
