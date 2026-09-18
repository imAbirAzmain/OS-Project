#!/usr/bin/env bash
# =============================================================================
# file_search.sh — searches for files inside an authorized base directory.
#
# Demonstrates classic Linux text/filesystem tools: find, sort, stat.
# The backend passes in an already-scoped base_dir (personal/one-to-one/
# group/global area) so the search can never see outside that scope.
#
# Usage:
#   file_search.sh <base_dir> <search_term> [extension]
# =============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

if [[ $# -lt 2 ]]; then
    echo "Usage: $(basename "$0") <base_dir> <search_term> [extension]" >&2
    exit "$EXIT_INVALID_ARGUMENT"
fi

base_dir="$1"
search_term="$2"
extension="${3:-}"

if [[ ! -d "$base_dir" ]]; then
    die "$EXIT_INVALID_PATH" "Base directory does not exist: $base_dir"
fi
base_real="$(_portable_realpath "$base_dir" ".")"

name_pattern="*${search_term}*"
if [[ -n "$extension" ]]; then
    name_pattern="*${search_term}*.${extension}"
fi

matches=()
while IFS= read -r m; do
    [[ -n "$m" ]] && matches+=("$m")
done < <(
    find "$base_real" -type f -iname "$name_pattern" -not -path '*/.*' 2>/dev/null \
        | while IFS= read -r f; do
              printf '%s\t%s\n' "$(file_stat_mtime_epoch "$f")" "$f"
          done \
        | sort -rn -k1,1 \
        | cut -f2-
)

count="${#matches[@]}"
emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit COUNT "$count"

index=0
if (( count > 0 )); then
    for f in "${matches[@]}"; do
        rel="${f#"$base_real"/}"
        size="$(file_stat_size "$f")"
        modified="$(file_stat_modified "$f")"
        emit "RESULT_${index}_NAME" "$(basename -- "$f")"
        emit "RESULT_${index}_PATH" "$rel"
        emit "RESULT_${index}_SIZE" "$size"
        emit "RESULT_${index}_MODIFIED" "$modified"
        index=$((index + 1))
    done
fi

exit "$EXIT_SUCCESS"
