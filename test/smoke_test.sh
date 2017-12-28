#!/bin/bash

set -e

mix credo --mute-exit-status
mix credo list --mute-exit-status
mix credo suggest --mute-exit-status

mix credo lib/credo/sources.ex:1:11 --mute-exit-status
mix credo explain lib/credo/sources.ex:1:11 --mute-exit-status

mix credo.gen.check lib/my_first_credo_check.ex
mix credo.gen.config

mix credo categories
mix credo help
mix credo version

mix credo -h
mix credo -v


echo ""
echo "Smoke test succesful."
