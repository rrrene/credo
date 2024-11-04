#!/bin/bash

set -e

mix compile --force --warnings-as-errors


mix credo --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo --strict --enable-disabled-checks . --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo --strict --enable-disabled-checks . --mute-exit-status --format=json 2>&1 | ./test/error_if_warnings.sh

mix credo lib/credo.ex --read-from-stdin --strict < lib/credo.ex 2>&1 | ./test/error_if_warnings.sh

mix credo list --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo suggest --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo diff HEAD^ --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo diff v1.4.0 --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo explain test/fixtures/example_code/clean_redux.ex:1:11 --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo explain Credo.Check.Refactor.Nesting --mute-exit-status 2>&1 | ./test/error_if_warnings.sh

mix credo categories 2>&1 | ./test/error_if_warnings.sh

mix credo info --verbose 2>&1 | ./test/error_if_warnings.sh

mix credo version 2>&1 | ./test/error_if_warnings.sh

mix credo help 2>&1 | ./test/error_if_warnings.sh


echo ""
echo "Smoke test for runtime warnings successful."
