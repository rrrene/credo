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

# setup

cd $PROJECT_ROOT

mkdir -p tmp

mix deps.get
mix compile

# execution

# Community projects
sh $DIRNAME/run_on_project.sh https://github.com/elixirscript/elixirscript.git elixirscript
sh $DIRNAME/run_on_project.sh https://github.com/ueberauth/guardian.git guardian
sh $DIRNAME/run_on_project.sh https://github.com/bitwalker/distillery.git distillery
sh $DIRNAME/run_on_project.sh https://github.com/bitwalker/timex.git timex
sh $DIRNAME/run_on_project.sh https://github.com/michalmuskala/jason.git jason
sh $DIRNAME/run_on_project.sh https://github.com/thoughtbot/ex_machina.git ex_machina
sh $DIRNAME/run_on_project.sh https://github.com/graphql-elixir/graphql.git graphql
sh $DIRNAME/run_on_project.sh https://github.com/absinthe-graphql/absinthe.git absinthe
sh $DIRNAME/run_on_project.sh https://github.com/devinus/poison.git poison
sh $DIRNAME/run_on_project.sh https://github.com/dashbitco/mox.git mox
sh $DIRNAME/run_on_project.sh https://github.com/PragTob/benchee.git benchee

# Elixir
sh $DIRNAME/run_on_project.sh https://github.com/elixir-lang/elixir.git elixir
sh $DIRNAME/run_on_project.sh https://github.com/elixir-lang/ex_doc.git ex_doc
sh $DIRNAME/run_on_project.sh https://github.com/elixir-lang/flow.git flow
sh $DIRNAME/run_on_project.sh https://github.com/elixir-lang/gettext.git gettext
sh $DIRNAME/run_on_project.sh https://github.com/elixir-lang/gen_stage.git gen_stage
sh $DIRNAME/run_on_project.sh https://github.com/elixir-ecto/ecto.git ecto
sh $DIRNAME/run_on_project.sh https://github.com/elixir-plug/plug.git plug

# Phoenix
sh $DIRNAME/run_on_project.sh https://github.com/phoenixframework/phoenix.git phoenix
sh $DIRNAME/run_on_project.sh https://github.com/phoenixframework/phoenix_html.git phoenix_html
sh $DIRNAME/run_on_project.sh https://github.com/phoenixframework/phoenix_pubsub.git phoenix_pubsub
sh $DIRNAME/run_on_project.sh https://github.com/phoenixframework/phoenix_ecto.git phoenix_ecto
sh $DIRNAME/run_on_project.sh https://github.com/phoenixframework/phoenix_live_reload.git phoenix_live_reload

# Nerves
sh $DIRNAME/run_on_project.sh https://github.com/nerves-project/nerves.git nerves

# teardown

echo ""
echo "All tests done."
