#!/usr/bin/env bash
# Source this file:  source scripts/setup_ciel_env.sh
# Auto-detects the three SKY130 HD liberty files from a Ciel installation.
set -e

CIEL_ROOT="${PDK_ROOT:-$HOME/.ciel}"

find_one() {
  local name="$1"
  find "$CIEL_ROOT" -type f -name "$name" 2>/dev/null | head -n 1
}

export SKY130_LIB_TT="${SKY130_LIB_TT:-$(find_one sky130_fd_sc_hd__tt_025C_1v80.lib)}"
export SKY130_LIB_MAX="${SKY130_LIB_MAX:-$(find_one sky130_fd_sc_hd__ss_100C_1v60.lib)}"
export SKY130_LIB_MIN="${SKY130_LIB_MIN:-$(find_one sky130_fd_sc_hd__ff_n40C_1v95.lib)}"

for v in SKY130_LIB_TT SKY130_LIB_MAX SKY130_LIB_MIN; do
  val="${!v:-}"
  if [[ -z "$val" || ! -f "$val" ]]; then
    echo "ERROR: Could not locate $v under $CIEL_ROOT" >&2
    echo "Run: find ~/.ciel -name 'sky130_fd_sc_hd__*.lib' | head" >&2
    return 1 2>/dev/null || exit 1
  fi
done

echo "SKY130_LIB_TT=$SKY130_LIB_TT"
echo "SKY130_LIB_MAX=$SKY130_LIB_MAX"
echo "SKY130_LIB_MIN=$SKY130_LIB_MIN"
