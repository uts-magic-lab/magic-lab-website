#!/bin/sh -e

if [ -z "$1" ]; then
    echo "usage: $0 [hash]"
    exit 1
fi

SOURCE_DIR="$( cd "$( dirname "$0" )" && pwd )"
PUBLISH_DIR="$SOURCE_DIR/public"
PUBLISH_BRANCH=gh-pages

# OpenShift support
if [ -n "$OPENSHIFT_APP_NAME" ]; then
    echo "Configuring git on OpenShift"
    export GIT_DIR="${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_APP_NAME}.git"
else
    export GIT_DIR="$SOURCE_DIR/.git"
fi

COMMIT_ID=$(git rev-parse "$1")

# Publish the commit
if [ "$(git merge-base "$COMMIT_ID" "$PUBLISH_BRANCH")" = "$COMMIT_ID" ]; then
    rm -rf "$PUBLISH_DIR" || true
    mkdir -p "$PUBLISH_DIR"
    git archive "$COMMIT_ID" | tar -x -C "$PUBLISH_DIR"
    echo "Published commit '$1' to './public/'"
else
    echo "$0: Not a valid commit id: '$1'"
    exit 2
fi
