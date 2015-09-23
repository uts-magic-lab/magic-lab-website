#!/bin/sh -e

# usage: publish.sh [commit id]

# Knobs
SOURCE_DIR="$( cd "$( dirname "$0" )" && pwd )"
PUBLISH_DIR="$SOURCE_DIR/public"
PUBLISH_BRANCH=gh-pages
COMMIT_NAME="${1:-$PUBLISH_BRANCH}"

# OpenShift support
if [ -n "$OPENSHIFT_APP_NAME" ]; then
    echo "Configuring git on OpenShift."
    export GIT_DIR="${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_APP_NAME}.git"
else
    export GIT_DIR="$SOURCE_DIR/.git"
fi

# Verify the commit is on the right branch
COMMIT_ID=$(git rev-parse "$COMMIT_NAME")
if [ "$(git merge-base "$COMMIT_ID" "$PUBLISH_BRANCH")" != "$COMMIT_ID" ]; then
    echo "$0: Not a valid commit id: '$COMMIT_NAME'"
    exit 2
fi

# Show progress compactly
function lines_to_dots()
{
    while read f; do
        printf "."
    done
    printf "\n"
}

# Publish the commit
printf "Publishing commit '$COMMIT_NAME' to './public/'"
rm -rf "$PUBLISH_DIR" || true
mkdir -p "$PUBLISH_DIR"
git archive "$COMMIT_ID" | tar -xv -C "$PUBLISH_DIR" 2>&1 | lines_to_dots

echo 'Done.'
