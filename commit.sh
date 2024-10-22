#!/bin/sh -e

# Usage: commit.sh [commit message]

SOURCE_DIR="$( cd "$( dirname "$0" )" && pwd )"
#PUBLISH_DIR="$SOURCE_DIR/public"
PUBLISH_DIR="$DEST_PATH"

SOURCE_BRANCH=master
PUBLISH_BRANCH=gh-pages

# OpenShift support
if [ -n "$OPENSHIFT_APP_NAME" ]; then
    echo "Configuring git on OpenShift"
    export GIT_DIR="${OPENSHIFT_HOMEDIR}git/${OPENSHIFT_APP_NAME}.git"
    mkdir -p "$OPENSHIFT_DATA_DIR/.ssh"
    echo "ssh -o UserKnownHostsFile=$OPENSHIFT_DATA_DIR/.ssh/known_hosts -i $OPENSHIFT_APP_SSH_KEY \$@" > /tmp/git_ssh
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

if [ -n "$REBUILD_FIRST" -o ! -d "$PUBLISH_DIR/.git" ]; then
    echo "Building preview dir for repository."
    rm -rf "$PUBLISH_DIR"
    git clone --shared --no-checkout "$GIT_DIR" "$PUBLISH_DIR"
    echo "ref: refs/heads/${PUBLISH_BRANCH}" > "${PUBLISH_DIR}/.git/HEAD"
    (
        cd "$PUBLISH_DIR"
        unset GIT_DIR
        git checkout --force "$PUBLISH_BRANCH" || git checkout --orphan "$PUBLISH_BRANCH"
        rm -rf *
    )

    # build with a script that will terminate
    gulp build ${DEBUG_COLORS:+--color}
fi

# commit the result
(
    echo "Committing current preview dir."
    cd "$PUBLISH_DIR"
    unset GIT_DIR
    git add --all .
    git commit -m "$COMMIT_MESSAGE"
    git push origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"
)

if [ -n "$PUBLISH_IMMEDIATELY" ]; then
    echo "Publishing immediately."
    ./publish.sh "$PUBLISH_BRANCH"
fi

# upload result
if [ -n "$OPENSHIFT_APP_NAME" ]; then
    echo "Uploading results."
    git push origin "${PUBLISH_BRANCH}:${PUBLISH_BRANCH}"
fi
