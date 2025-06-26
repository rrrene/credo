#!/bin/bash

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
CREDO_ROOT=$( cd "$DIRNAME/../.." && pwd )

# script specific sources, variables and function definitions

OLD_CREDO_VERSION=$1
GIT_REPO=$2
PROJECT_NAME=$3

mkdir -p tmp

WORKING_DIR=$( cd "$CREDO_ROOT/tmp/$PROJECT_NAME" && pwd )

cd tmp

rm -fr $PROJECT_NAME
git clone $GIT_REPO $PROJECT_NAME --depth=1 --quiet

cd $CREDO_ROOT

# TODO: add --enable-disabled-checks .

mix credo --working-dir $WORKING_DIR \
    --strict --format oneline --mute-exit-status | sort | sed -e 's/tmp\///g' > tmp/results_current.txt

cp test/regression/run_older_credo_version.exs tmp/
cd tmp

mix run --no-mix-exs run_older_credo_version.exs $OLD_CREDO_VERSION --working-dir $WORKING_DIR \
    --strict --format oneline --mute-exit-status | sort | sed -e 's/tmp\///g' > results_old.txt

diff results_old.txt results_current.txt && echo "No differences in issues."