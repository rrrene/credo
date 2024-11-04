#!/bin/bash

set -e

mix compile --force --warnings-as-errors


mix credo --mute-exit-status | ./test/error_if_warnings.sh

mix credo --strict --enable-disabled-checks . --mute-exit-status | ./test/error_if_warnings.sh

mix credo --strict --enable-disabled-checks . --mute-exit-status --format=json | ./test/error_if_warnings.sh

mix credo lib/credo.ex --read-from-stdin --strict < lib/credo.ex | ./test/error_if_warnings.sh

mix credo list --mute-exit-status | ./test/error_if_warnings.sh

mix credo suggest --mute-exit-status | ./test/error_if_warnings.sh

mix credo diff HEAD^ --mute-exit-status | ./test/error_if_warnings.sh

mix credo diff v1.4.0 --mute-exit-status | ./test/error_if_warnings.sh

mix credo explain test/fixtures/example_code/clean_redux.ex:1:11 --mute-exit-status | ./test/error_if_warnings.sh

mix credo explain Credo.Check.Refactor.Nesting --mute-exit-status | ./test/error_if_warnings.sh

mix credo categories | ./test/error_if_warnings.sh

mix credo info --verbose | ./test/error_if_warnings.sh

mix credo version | ./test/error_if_warnings.sh

mix credo help | ./test/error_if_warnings.sh


echo ""
echo "Smoke test for runtime warnings successful."
