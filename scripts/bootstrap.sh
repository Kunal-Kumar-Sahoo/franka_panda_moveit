#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

git submodule update --init --recursive

git apply --check migration/franka_ros.patch
git apply --check migration/boost_sml.patch

git apply --directory=src/franka_ros migration/franka_ros.patch
git apply --directory=src/boost_sml migration/boost_sml.patch

echo "Source patches applied successfully."
