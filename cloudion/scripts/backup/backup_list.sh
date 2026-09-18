#!/usr/bin/env bash
# backup_list.sh — lists available backup archives, newest first.
# Usage: backup_list.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

ensure_dir "$BACKUPS_ROOT" 0750

archives=()
while IFS= read -r a; do
    [[ -n "$a" ]] && archives+=("$a")
done < <(
    find "$BACKUPS_ROOT" -maxdepth 1 -name '*.tar.gz' 2>/dev/null \
    | while IFS= read -r f; do
          printf '%s\t%s\n' "$(file_stat_mtime_epoch "$f")" "$f"
      done \
    | sort -rn -k1,1 \
    | cut -f2-
)

count="${#archives[@]}"
emit STATUS SUCCESS
emit CODE "$EXIT_SUCCESS"
emit COUNT "$count"

index=0
if (( count > 0 )); then
    for a in "${archives[@]}"; do
        size="$(file_stat_size "$a")"
        modified="$(file_stat_modified "$a")"
        emit "BACKUP_${index}_NAME" "$(basename -- "$a")"
        emit "BACKUP_${index}_SIZE" "$size"
        emit "BACKUP_${index}_DATE" "$modified"
        index=$((index + 1))
    done
fi
exit "$EXIT_SUCCESS"
