#!/bin/bash

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
CREDO_ROOT=$( cd "$DIRNAME/.." && pwd )

# script specific sources, variables and function definitions

CREDO_ARG1=$1
CREDO_ARG2=$2
CREDO_ARG3=$3
CREDO_ARG4=$4
CREDO_ARG5=$5
CREDO_ARG6=$6
CREDO_ARG7=$7
CREDO_ARG8=$8
CREDO_ARG9=$9

# setup

cd $CREDO_ROOT

mkdir -p tmp


echo ""
echo "Diffing old and new issues ..."
echo ""

elixir test/old_credo.exs -- $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5 $CREDO_ARG6 $CREDO_ARG7 $CREDO_ARG8 $CREDO_ARG9

elixir test/old_credo.exs . -- $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5 $CREDO_ARG6 $CREDO_ARG7 $CREDO_ARG8 $CREDO_ARG9

elixir test/old_credo.exs -- $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5 $CREDO_ARG6 $CREDO_ARG7 $CREDO_ARG8 $CREDO_ARG9 > tmp/old_credo.txt

elixir test/old_credo.exs . -- $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5 $CREDO_ARG6 $CREDO_ARG7 $CREDO_ARG8 $CREDO_ARG9 > tmp/new_credo.txt

diff --color tmp/old_credo.txt tmp/new_credo.txt && echo "--- no diff ---"
