#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

git submodule update --init --recursive

git -C src/franka_ros apply --check "$ROOT/migration/franka_ros.patch"
git -C src/boost_sml apply --check "$ROOT/migration/boost_sml.patch"

git -C src/franka_ros apply "$ROOT/migration/franka_ros.patch"
git -C src/boost_sml apply "$ROOT/migration/boost_sml.patch"

echo "Source patches applied successfully."
