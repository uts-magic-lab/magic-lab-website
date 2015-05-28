#!/bin/sh -ex

# Usage: publish.sh [commit message]

SOURCE_DIR=$( cd "$( dirname "$0" )" && pwd )
PUBLISH_DIR="$SOURCE_DIR"/public

SOURCE_BRANCH=master
PUBLISH_BRANCH=gh-pages

# OpenShift support
if [ -n "$OPENSHIFT_APP_NAME" ]; then
    export GIT_DIR="${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_APP_NAME}.git"
    echo "ssh -i $OPENSHIFT_APP_SSH_KEY \$@" > /tmp/git_ssh
    chmod +x /tmp/git_ssh
    export GIT_SSH=/tmp/git_ssh
else
    export GIT_DIR="$SOURCE_DIR/.git"
fi

COMMIT_MESSAGE="$@"
if [ -z "$COMMIT_MESSAGE" ]; then
    COMMIT_MESSAGE="$(git log -1 --pretty=%B) (built by $0)"
fi


# ensure the publish branch is up to date and in place in the publish folder
git fetch --force origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"
PUBLISH_PARENT=$(git rev-parse -q --verify "$PUBLISH_BRANCH" || true)

rm -rf "$PUBLISH_DIR"
git clone --no-checkout "$GIT_DIR" "$PUBLISH_DIR"

if [ -n "$PUBLISH_PARENT" ]; then
    (cd "$PUBLISH_DIR"; git checkout --force "$PUBLISH_BRANCH"; rm -rf *)
else
    (cd "$PUBLISH_DIR"; git checkout --orphan "$PUBLISH_BRANCH"; rm -rf *)
fi

# build with a script that will terminate
gulp build ${DEBUG_COLORS:+--color}

(
    git add --all .
    git commit -m "$COMMIT_MESSAGE"
    git push origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"
)
