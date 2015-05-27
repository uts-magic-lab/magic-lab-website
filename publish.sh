#!/bin/sh -ex

# Usage: publish.sh [commit message]

SOURCE_DIR=$( cd "$( dirname "$0" )" && pwd )

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

PUBLISH_DIR="$SOURCE_DIR"/public
PUBLISH_BRANCH=gh-pages
SOURCE_BRANCH=master

SOURCE_PARENT=$(git rev-parse -q --verify $SOURCE_BRANCH)

# ensure the publish branch is up to date and in place in the publish folder
git fetch --force origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"
PUBLISH_PARENT=$(git rev-parse -q --verify "$PUBLISH_BRANCH" || true)

mkdir -p "$PUBLISH_DIR"
if [ -n "$PUBLISH_PARENT" ]; then
    (cd "$PUBLISH_DIR"; git checkout --force "$PUBLISH_BRANCH"; rm -rf *)
else
    (cd "$PUBLISH_DIR"; git checkout --orphan "$PUBLISH_BRANCH"; rm -rf *)
fi

# build with a script that will terminate
gulp build ${DEBUG_COLORS:+--color}

git --work-tree="$PUBLISH_DIR" add --all .
git update-ref refs/heads/"$PUBLISH_BRANCH" $(
    git commit-tree \
        ${PUBLISH_PARENT:+-p $PUBLISH_PARENT} \
        -m "$COMMIT_MESSAGE" \
        $(git write-tree)
)

git push origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"

git reset "$SOURCE_BRANCH"
git checkout "$SOURCE_BRANCH"
