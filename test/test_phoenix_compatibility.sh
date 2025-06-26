#!/bin/bash

##
## Ensures that a fresh Phoenix project does not trigger any issue in "normal" mode
##

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
CREDO_ROOT=$( cd "$DIRNAME/.." && pwd )

# script specific sources, variables and function definitions

PROJECT_NAME=phx_credo_tester
PROJECT_DIRNAME=tmp/$PROJECT_NAME

# setup

yes | mix archive.install hex phx_new

cd $CREDO_ROOT

mkdir -p tmp

echo ""
echo "--> Creating $PROJECT_NAME ..."
echo ""

rm -fr $PROJECT_DIRNAME || true

cd tmp
yes n | mix phx.new $PROJECT_NAME

# execution

echo ""
echo "--> Running Credo ..."
echo ""

cd $CREDO_ROOT

mix credo $PROJECT_DIRNAME
