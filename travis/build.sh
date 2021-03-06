#!/bin/bash
set -ex

# Smoke test sky_shell.
./out/sky_shell --help

# Run the tests.
pushd sky/unit
SKY_SHELL=../../out/sky_shell ../../third_party/dart-sdk/dart-sdk/bin/pub run sky_tools:sky_test -j 1
popd

# Analyze the code.
pushd sky/packages/sky
../../../third_party/dart-sdk/dart-sdk/bin/dartanalyzer --supermixin lib/widgets.dart
popd

# Generate docs.
./sky/tools/skydoc.py
