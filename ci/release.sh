#!/bin/bash
#
# This versions and releases a config repo.
#
# It reuqires the repo name as an argument. It accepts the environment variables
#   `RELEASE_VERSION`
#   `DEVELOPMENT_VERSION`
#

set -e  # die on error
set -o pipefail  # die on error within pipes

### Validate argument

if [ "$1" = "" ]
then
  echo "Usage: $0 <name of repository to be released>"
  exit
fi

### Configure Github

git remote remove central || true
git remote add central git@github.com:PIH/$1.git
git config --global user.email "pihinformatics@gmail.com"
git config --global user.name "pihinformatics"
git fetch central

### Clean up

# For these to work, it's important that the Bamboo has git repository caching disabled for this repo/job.
# Reset
git reset --hard central/master
# Clean up stray local tags that didn't get pushed
git tag -l | xargs git tag -d
git fetch central --tags

### Figure out versions

CURRENT_RELEASE_TARGET=$(grep -m 1 "<version>" pom.xml | sed 's/.*version>\(.*\)-SNAPSHOT<\/version.*/\1/')

if [ -z "${RELEASE_VERSION}" ]; then
    RELEASE_VERSION=$CURRENT_RELEASE_TARGET
fi

echo RELEASE_VERSION ${RELEASE_VERSION}

if [ -z "${DEVELOPMENT_VERSION}" ]; then
    MAJOR=$(echo "${RELEASE_VERSION#v}" | cut -f1 -d.)
    MINOR=$(echo "${RELEASE_VERSION#v}" | cut -f2 -d.)
    PATCH=$(echo "${RELEASE_VERSION#v}" | cut -f3 -d.)
    NEW_MINOR="$(( ${MINOR} + 1 ))"
    DEVELOPMENT_VERSION="${MAJOR}.${NEW_MINOR}.0-SNAPSHOT"
fi

echo DEVELOPMENT_VERSION ${DEVELOPMENT_VERSION}

### Do release

set -x  # print all commands

# Update version to release version
sed -i "0,/<\/version>/{s/version>.*-SNAPSHOT<\/version/version>${RELEASE_VERSION}<\/version/}" pom.xml
git add pom.xml
git commit -m "${RELEASE_VERSION} release"
git tag ${RELEASE_VERSION}
git push central master --tags

### Prep for next development cycle
sed -i "0,/<\/version>/{s/version>.*<\/version/version>${DEVELOPMENT_VERSION}<\/version/}" pom.xml
git add pom.xml
git commit -m "update to ${DEVELOPMENT_VERSION}"
git push central master
