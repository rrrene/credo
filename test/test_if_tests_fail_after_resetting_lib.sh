#!/bin/bash

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
PROJECT_ROOT=$( cd "$DIRNAME/.." && pwd )

# execution

cd $PROJECT_ROOT

git checkout master lib/

if mix test ; then
  echo ""
  echo "------------------------------------------------------------------"
  echo ""
  echo "There are changes to both lib/ and test/ which can indicate"
  echo "a bugfix with a corresponding test that reproduces the fixed bug"
  echo ""
  echo "(if this is not a bugfix PR, please ignore the following error)"
  echo ""
  echo "\e[31mAfter resetting changes in lib/, mix test should have failed"
  echo ""
  echo "------------------------------------------------------------------"
  echo ""
  exit 1
else
  exit 0
fi
