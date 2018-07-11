#!/bin/bash

# common setup

set -e

DIRNAME=$( cd "$( dirname "$0" )" && pwd )
PROJECT_ROOT=$( cd "$DIRNAME/.." && pwd )

# script specific sources, variables and function definitions

METRIC_BASE=${1:-full}
CREDO_ARG1=$2
CREDO_ARG2=$3
CREDO_ARG3=$4
CREDO_ARG4=$5
CREDO_ARG5=$6

clone_and_test() {
  GIT_REPO=$1
  PROJECT_NAME=$2
  PROJECT_DIRNAME=tmp/$PROJECT_NAME
  METRIC="$METRIC_BASE,project=$PROJECT_NAME,branch=$GIT_BRANCH"
  CMD="mix credo $PROJECT_DIRNAME --mute-exit-status --format json --strict $CREDO_ARG1 $CREDO_ARG2 $CREDO_ARG3 $CREDO_ARG4 $CREDO_ARG5"

  echo ""
  echo "--> Cloning $PROJECT_NAME ..."

  rm -fr $PROJECT_DIRNAME || true
  git clone $GIT_REPO $PROJECT_DIRNAME --depth=1 --quiet

  echo "--> Analysing $PROJECT_NAME ..."
  echo ""

  benchmark "$CMD" "$METRIC"
  #check_compatibility_with_formatter "$PROJECT_DIRNAME"
}

check_compatibility_with_formatter() {
  PROJECT_DIRNAME=$1

  cd $PROJECT_DIRNAME
  rm .tool-versions || true

  # format code
  mix format {src,lib}/**/*.{ex,exs} || true

  # there should not be any readbility or consistency issues after using the formatter
  cd $PROJECT_ROOT
  mix credo $PROJECT_DIRNAME \
    --mute-exit-status \
    --format json \
    --only Readability,Consistency \
    --ignore ModuleDoc,MultiAliasImportRequireUse,Specs,ParenthesesOnZeroArityDefs,PreferImplicitTry
}

benchmark() {
  COMMAND=$1 # command to be timed/benchmarked
  METRIC=$2 # metric to be collected

  # The '%N' option does not seem to work on macOS
  t1=$(date +%s%N)
  bash -c "$COMMAND"
  t2=$(date +%s%N)
  TIME=`expr $t2 - $t1`
  TIME=`expr $TIME / 1000000`

  echo "$METRIC:$TIME|ms" | nc -C -w 1 -u $STATSD_HOST $STATSD_PORT
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
clone_and_test https://github.com/elixir-plug/plug.git plug

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
