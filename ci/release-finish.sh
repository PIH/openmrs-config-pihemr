#!/bin/bash
#
# This versions a config repo to the next SNAPSHOT version,
# and updates pihcore to refer to the correct SNAPSHOT version.
#
# It requires the repo name as an argument.
# It accepts the environment variables
#   `DEVELOPMENT_VERSION`
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

BRANCH=${2:-master}

### Configure Github

git config --global user.email "pihinformatics@gmail.com"
git config --global user.name "pihinformatics"

git remote remove central || true
git remote add central git@github.com:PIH/$1.git
git fetch central

cd openmrs-module-pihcore
git remote remove central || true
git remote add central git@github.com:PIH/openmrs-module-pihcore.git
git fetch central
cd ..

### Clean up

# For these to work, it's important that the Bamboo has git repository caching disabled for this repo/job.
# Reset
git reset --hard central/${BRANCH}
# Clean up stray local tags that didn't get pushed
git tag -l | xargs git tag -d
git fetch central --tags

### Figure out versions

# POM should currently have release version from `release-prepare.sh`
RELEASE_VERSION=$(grep -m 1 "<version>" pom.xml | sed 's/.*version>\(.*\)<\/version.*/\1/')

if [ -z "${DEVELOPMENT_VERSION}" ]; then
    MAJOR=$(echo "${RELEASE_VERSION#v}" | cut -f1 -d.)
    MINOR=$(echo "${RELEASE_VERSION#v}" | cut -f2 -d.)
    PATCH=$(echo "${RELEASE_VERSION#v}" | cut -f3 -d.)
    NEW_MINOR="$(( ${MINOR} + 1 ))"
    DEVELOPMENT_VERSION="${MAJOR}.${NEW_MINOR}.0-SNAPSHOT"
fi

echo DEVELOPMENT_VERSION ${DEVELOPMENT_VERSION}

### Prep for next development cycle
sed -i "0,/<\/version>/{s/version>.*<\/version/version>${DEVELOPMENT_VERSION}<\/version/}" pom.xml
git add pom.xml
if ! git diff --cached --exit-code; then
  git commit -m "update to ${DEVELOPMENT_VERSION}"
  git push central ${BRANCH}
fi

### Update development version in pihcore

cd openmrs-module-pihcore

# https://www.baeldung.com/linux/sed-editor
sed -n -i \
  "/$1/{h; n; s/<version>.*<\/version>/<version>${DEVELOPMENT_VERSION}<\/version>/; x; p; x}; p" \
  api/pom.xml
# sed \     # the stream editor
# -n \      # don't automatically print each line
# -i \      # replace the file contents
# "/$1/{    # search for the config repo name. If found, execute the function in curly braces.
#     h;    # 'put the line in hold space'--i.e. save the repo name line for later
#     n;    # go to the next line and execute the following replacement
#     s/<version>.*<\/version>/<version>2.0.0-SNAPSHOT<\/version>/;
#     x;    # exchange the active line (the version line) with the held line (the repo name)
#     p;    # print out the repo name line
#     x     # exchange them back so the active line is again the version line
#           #   and will be printed by the `p` below
#   };
# p"        # print whatever's active. Note that this is different than if we just didn't use
#           #   the `-n` flag. I struggle to explain why.

git add api/pom.xml
if ! git diff --cached --exit-code; then
  git commit -m "Update $1 version to ${DEVELOPMENT_VERSION}"
  git push central `git rev-parse --abbrev-ref HEAD`
fi
cd ..
