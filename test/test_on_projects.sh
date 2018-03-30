#!/bin/bash

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
PROJECT_ROOT=$( cd "$DIRNAME/.." && pwd )

# script specific sources, variables and function definitions

CREDO_ARG1=$1
CREDO_ARG2=$2
CREDO_ARG3=$3
CREDO_ARG4=$4
CREDO_ARG5=$5

clone_and_test() {
  GIT_REPO=$1
  PROJECT_NAME=$2
  DIRNAME=tmp/$PROJECT_NAME
  METRIC=$PROJECT_NAME
  CMD="mix credo $DIRNAME --mute-exit-status --format json --strict $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5"

  echo ""
  echo "--> Cloning $PROJECT_NAME ..."

  rm -fr $DIRNAME || true
  git clone $GIT_REPO $DIRNAME --depth=1 --quiet

  echo "--> Analysing $PROJECT_NAME ..."
  echo ""

  benchmark "$CMD" "" "" "$METRIC"
}

benchmark() {
  COMMAND=$1 # command to be timed/benchmarked
  HOST=$2 # hostname of statsd listener
  PORT=$3 # port of statsd listener
  METRIC=$4 # metric to be collected

  # The '%N' option does not seem to work on macOS
  t1=$(date +%s%N)
  bash -c "$COMMAND"
  t2=$(date +%s%N)
  TIME=`expr $t2 - $t1`
  TIME=`expr $TIME / 1000000`

  echo "$METRIC:$TIME|ms" #| nc -C -w 1 -u $HOST $PORT
}

# setup

cd $PROJECT_ROOT

mkdir -p tmp

mix deps.get
mix compile

# execution

# Community projects
clone_and_test https://github.com/elixirscript/elixirscript.git elixirscript
clone_and_test https://github.com/ueberauth/guardian.git guardian
clone_and_test https://github.com/bitwalker/distillery.git distillery
clone_and_test https://github.com/bitwalker/timex.git timex
clone_and_test https://github.com/michalmuskala/jason.git jason
clone_and_test https://github.com/thoughtbot/ex_machina.git ex_machina
clone_and_test https://github.com/graphql-elixir/graphql.git graphql
clone_and_test https://github.com/absinthe-graphql/absinthe.git absinthe
clone_and_test https://github.com/devinus/poison.git poison
clone_and_test https://github.com/plataformatec/mox.git mox
clone_and_test https://github.com/PragTob/benchee.git benchee

# Elixir
clone_and_test https://github.com/elixir-lang/elixir.git elixir
clone_and_test https://github.com/elixir-lang/ex_doc.git ex_doc
clone_and_test https://github.com/elixir-lang/flow.git flow
clone_and_test https://github.com/elixir-lang/gettext.git gettext
clone_and_test https://github.com/elixir-lang/gen_stage.git gen_stage
clone_and_test https://github.com/elixir-ecto/ecto.git ecto

# Phoenix
clone_and_test https://github.com/phoenixframework/phoenix.git phoenix
clone_and_test https://github.com/phoenixframework/phoenix_html.git phoenix_html
clone_and_test https://github.com/phoenixframework/phoenix_pubsub.git phoenix_pubsub
clone_and_test https://github.com/phoenixframework/phoenix_ecto.git phoenix_ecto
clone_and_test https://github.com/phoenixframework/phoenix_live_reload.git phoenix_live_reload

# Nerves
clone_and_test https://github.com/nerves-project/nerves.git nerves

# teardown

echo ""
echo "All tests done."
