#!/usr/bin/env bash
# Generate Dart gRPC/protobuf stubs from proto/openflight.proto.
#
# Prerequisites:
#   dart pub global activate protoc_plugin
#   brew install protobuf  (macOS) OR  apt install protobuf-compiler
#
# Run from the mobile/ directory:
#   bash scripts/generate_proto.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$MOBILE_DIR"

echo "Generating Dart proto stubs..."
protoc \
  --dart_out=grpc:"$MOBILE_DIR/lib/proto" \
  -I"$MOBILE_DIR/proto" \
  "$MOBILE_DIR/proto/openflight.proto"

echo "Done. Files written to lib/proto/"
