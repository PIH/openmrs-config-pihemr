#!/bin/bash
#
# This versions a config repo to its release version,
# preparing it for a Maven deploy.
#
# It requires the repo name as an argument.
# It accepts the environment variables
#   `RELEASE_VERSION`
#
# This script requires that the config repo dependency entries
# in openmrs-module-pihcore/api/pom.xml have the version line
# immediately following the `artifactId` line. e.g.
#
# <groupId>org.pih.openmrs</groupId>
# <artifactId>openmrs-config-ces</artifactId>
# <version>1.0.0-SNAPSHOT</version>
#
# If the version line is not immediately after the artifactId line,
# terrible things will happen.
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

git config --global user.email "pihinformatics@gmail.com"
git config --global user.name "pihinformatics"

git remote remove central || true
git remote add central git@github.com:PIH/$1.git
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

### Do release

set -x  # print all commands

# Update version to release version
sed -i "0,/<\/version>/{s/version>.*-SNAPSHOT<\/version/version>${RELEASE_VERSION}<\/version/}" pom.xml
git add pom.xml
git commit -m "${RELEASE_VERSION} release"
git tag ${RELEASE_VERSION}
git push central master --tags
