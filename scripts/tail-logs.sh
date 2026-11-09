#!/usr/bin/env bash
# Usage: ./scripts/tail-logs.sh [lambda|api]   (default: lambda)
set -euo pipefail

NAME="${NAME:-items-api-dev}"
case "${1:-lambda}" in
  lambda) GROUP="/aws/lambda/$NAME" ;;
  api)    GROUP="/aws/apigateway/$NAME" ;;
  *) echo "Usage: $0 [lambda|api]"; exit 2 ;;
esac

echo "Tailing $GROUP (Ctrl+C to stop)"
aws logs tail "$GROUP" --follow --since 10m
