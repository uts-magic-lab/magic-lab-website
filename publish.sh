#!/bin/sh -ex

SOURCE_BRANCH=$(git rev-parse HEAD)
SOURCE_PARENT=$(git rev-parse -q --verify $SOURCE_BRANCH)
SOURCE_MESSAGE=$(git log -1 --pretty=%B)
PUBLISH_BRANCH=gh-pages
PUBLISH_PARENT=$(git rev-parse -q --verify "$PUBLISH_BRANCH" || true)
PUBLISH_DIR=public

if [ "$SOURCE_BRANCH" = "$PUBLISH_BRANCH" ]; then
    echo "Cannot publish from branch $SOURCE_BRANCH"
    exit 1
fi

rm -rf "$PUBLISH_DIR"
git clone . "$PUBLISH_DIR"
if [ -n "$PUBLISH_PARENT" ]; then
    (cd "$PUBLISH_DIR"; git checkout "$PUBLISH_BRANCH"; rm -r *)
else
    (cd "$PUBLISH_DIR"; git checkout --orphan "$PUBLISH_BRANCH"; rm -rf *)
fi

# build with a script that will terminate
gulp build

cd "$PUBLISH_DIR"
ln -s about.html index.html # TODO: move this into gulpfile
git add --all .
git update-ref refs/heads/"$PUBLISH_BRANCH" $(
    git commit-tree \
        ${PUBLISH_PARENT:+-p $PUBLISH_PARENT} \
        -m "$SOURCE_MESSAGE (built by $0)" \
        $(git write-tree)
)
git push origin "$PUBLISH_BRANCH"
