#!/usr/bin/env bash

BUILDKITE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$( cd "$BUILDKITE_DIR/.." && pwd )"
BIN_DIR="$BASE_DIR/bin"

# Load lib functions
lib_functions="$BIN_DIR/functions"
echo "Using version: ${SCRIPTS_VERSION:-stable}"
curl -Ls -o "${lib_functions}" "https://s3.amazonaws.com/bit-ops-artifacts/scripts/lib/${SCRIPTS_VERSION:-stable}/functions"
source "${lib_functions}"

formula(){
cat <<EOF
class Gaia < Formula
  desc "A wrapper script for Terraform"
  homepage "https://github.com/bandsintown/gaia"
  url "${url}"
  version "${version}"
  sha256 "${sha256}"

  def install
    bin.install "bin/gaia"
    prefix.install Dir["lib"]
  end
end
EOF
}

update_formula(){
  curl_options="-Ls --connect-timeout 10 --max-time 10 --retry 5 --retry-delay 5 --retry-max-time 60"
  local content_path="Formula/gaia.rb"
  info "Updating homebrew formula '${content_path}'..."

  ok=$(curl -w "%{http_code}" ${curl_options} \
    -H 'Accept: application/json' -XGET \
    "https://api.github.com/repos/${owner}/${repo}/contents/${content_path}?access_token=${access_token}" \
    -d "$(payload)" -o "${tmp}/response.json")

  if [ "200" != "${ok}" ]; then
    error "Error getting sha for ${content_path}"
    error "$(cat ${tmp}/response.json)"
    exit 1
  fi

  sha=$(cat "${tmp}/response.json" | jq -r ".sha")
  export sha

  ok=$(curl -w "%{http_code}" ${curl_options} \
    -H 'Content-Type: application/json' -XPUT \
    "https://api.github.com/repos/${owner}/${repo}/contents/${content_path}?access_token=${access_token}" \
    -d "$(payload)" -o "${tmp}/response.json")

  if [ "200" != "${ok}" ]; then
    error "Error updating homebrew formula on Github."
    error "$(cat ${tmp}/response.json)"
    exit 1
  fi

  html_url=$(cat ${tmp}/response.json | jq -r ".content .html_url")
  success "Homebrew formula '${content_path}' updated on Github."
  debug "See: '${html_url}'"
}

payload(){
formula="$(formula)"
content="$(echo -n "${formula}" | base64 | tr -d '\n')"
cat <<EOF
{
  "message": "Update gaia.rb formula (version ${version})",
  "committer": {
    "name": "${committer_name}",
    "email": "${committer_email}"
  },
  "content": "${content}",
  "sha": "${sha}"
}
EOF
}

# Prepare
tmp="$(mktemp -d)"

# Must be passed automatically by BuildKite
owner="${BUILDKITE_REPO#*:}"
owner="${owner%/*}"
repo="homebrew-tap"
committer_name="${BUILDKITE_BUILD_CREATOR}"
committer_email="${BUILDKITE_BUILD_CREATOR_EMAIL}"

# Must be set in the global environment hook
access_token=${GITHUB_ACCESS_TOKEN}
test -n "${access_token}" || { error "Please set the variable 'GITHUB_ACCESS_TOKEN' to deploy." ; exit 1;}
test -n "${owner}" || { error "Please set the variable 'BUILDKITE_REPO' to deploy." ; exit 1;}
test -n "${committer_name}" || { error "Please set the variable 'BUILDKITE_BUILD_CREATOR' to deploy." ; exit 1;}
test -n "${committer_email}" || { error "Please set the variable 'BUILDKITE_BUILD_CREATOR_EMAIL' to deploy." ; exit 1;}

version="$(buildkite-agent meta-data get release-name)"
test -n "${version}" || { error "Unable to read the Buildkite meta-data 'release-name'." ; exit 1;}
url="https://github.com/bandsintown/gaia/archive/${version}.tar.gz"
sha256="$(curl -Ls "${url}" | shasum -a 256 | awk '{print $1}')"
test -n "${sha256}" || { error "Unable to calculate sha256 from: ${url}" ; exit 1;}

update_formula