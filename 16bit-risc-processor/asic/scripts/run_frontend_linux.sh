#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Automatically locate Ciel-installed SKY130 liberty files if not already exported.
source scripts/setup_ciel_env.sh

mkdir -p reports

echo "[1/4] RTL self-check"
./scripts/run_rtl_sim.sh

echo "[2/4] SKY130 synthesis"
yosys -c scripts/synth_sky130.tcl

echo "[3/4] Setup STA"
sta scripts/sta_setup.tcl

echo "[4/4] Hold STA"
sta scripts/sta_hold.tcl

echo "DONE. Reports are in ./reports"
