#!/bin/sh -e

if [ -z "$1" ]; then
    echo "usage: $0 [hash]"
    exit 1
fi

COMMIT_ID=$(git rev-parse "$1")

SOURCE_DIR="$( cd "$( dirname "$0" )" && pwd )"
PUBLISH_DIR="$SOURCE_DIR/public"
PUBLISH_BRANCH=gh-pages

if [ "$(git merge-base "$COMMIT_ID" "$PUBLISH_BRANCH")" = "$COMMIT_ID" ]; then
    rm -rf "$PUBLISH_DIR" || true
    mkdir -p "$PUBLISH_DIR"
    git archive "$COMMIT_ID" | tar -x -C "$PUBLISH_DIR"
    echo "Published commit '$1' to './public/'"
else
    echo "$0: Not a valid commit id: '$1'"
    exit 2
fi
