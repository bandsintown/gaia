#!/usr/bin/env bash
set +x

RELEASE_NAME=$(buildkite-agent meta-data get release-name || echo "n/a")

# Define release hint for Github release
read -r -d '' release_hint << EOF
It’s common practice to prefix your version names with the letter v. Some good tag names might be v1.0 or v2.3.4.
If the tag isn’t meant for production use, add a pre-release version after the version name. Some good pre-release versions might be v0.2-alpha or v5.9-beta.3.
EOF

set -e

SHELLCHECK_VERSION=${SHELLCHECK_VERSION:-latest}

# Master banch before Github release
if [ "$RELEASE_NAME" == "n/a"  -a "$BUILDKITE_BRANCH" == 'master' ]; then
cat <<EOF
steps:
  - label: ':hammer: Run shellcheck'
    command: docker run -v "${PWD}:/mnt" koalaman/shellcheck:${SHELLCHECK_VERSION} bin/gaia lib/functions
  - wait
  - block: ':github: Release'
    prompt: "Fill out the details for release"
    fields:
      - text: "Release name"
        key: "release-name"
        required: true
        hint: "$release_hint"
      - text: "Describe this release"
        key: "release-notes"
        required: false
        hint: "List of what's changed in this release"
  - command: .buildkite/pipeline.sh | buildkite-agent pipeline upload
    label: ":pipeline: Setup pipeline"
EOF
exit 0
fi

# Master branch after Github release
if [ "$RELEASE_NAME" != "n/a" -a "$BUILDKITE_BRANCH" == 'master' ]; then
cat <<EOF
steps:
  - label: ':github: Release'
    command: .buildkite/release.sh
EOF
exit 0
fi

# Pull Requests
cat <<EOF
steps:
  - label: ':hammer: Run shellcheck'
    command: docker run -v "${PWD}:/mnt" koalaman/shellcheck:${SHELLCHECK_VERSION} bin/gaia lib/functions
EOF
