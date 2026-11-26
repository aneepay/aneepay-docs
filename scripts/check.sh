#!/usr/bin/env bash
# Run the same checks as CI: strict build, Markdown lint, link check.
set -euo pipefail

cd "$(dirname "$0")/.."

LYCHEE_ARGS=()
if ! curl -sS -o /dev/null --max-time 5 https://t.me/aneepay 2>/dev/null; then
  echo "note: Telegram is unreachable from this network, skipping t.me links"
  LYCHEE_ARGS=(--exclude 't\.me|telegram\.me')
fi

echo "== canonical site urls"
if grep -rn "aneepay\.github\.io/aneepay-docs" docs README.md; then
  echo "error: publish https://docs.aneepay.com, not the GitHub Pages address" >&2
  exit 1
fi

echo "== mkdocs build --strict"
mkdocs build --strict

echo "== markdownlint-cli2"
markdownlint-cli2 "docs/**/*.md"

echo "== lychee"
lychee --config lychee.toml --no-progress ${LYCHEE_ARGS[@]+"${LYCHEE_ARGS[@]}"} "docs/**/*.md"

echo "== all checks passed"
