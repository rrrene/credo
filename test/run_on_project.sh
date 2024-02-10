#!/bin/bash

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
CREDO_ROOT=$( cd "$DIRNAME/.." && pwd )

# script specific sources, variables and function definitions

GIT_REPO=$1
PROJECT_NAME=$2
CREDO_ARG1=$3
CREDO_ARG2=$4
CREDO_ARG3=$5
CREDO_ARG4=$6
CREDO_ARG5=$7

# setup

cd $CREDO_ROOT

mkdir -p tmp

echo ""
echo "--> Cloning $PROJECT_NAME ..."

PROJECT_DIRNAME=tmp/$PROJECT_NAME

rm -fr $PROJECT_DIRNAME || true
git clone $GIT_REPO $PROJECT_DIRNAME --depth=1 --quiet

echo "--> Analysing $PROJECT_NAME ..."
echo ""

CMD="mix credo $PROJECT_DIRNAME --mute-exit-status --format json --strict $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5"

bash -c "time $CMD"
