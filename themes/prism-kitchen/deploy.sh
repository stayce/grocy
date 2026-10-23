#!/bin/bash
# Deploy only Grocy's two persistent theme hooks. No direct database writes.
set -euo pipefail

task_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
deploy_host="${GROCY_DEPLOY_HOST:?Set GROCY_DEPLOY_HOST to the SSH user and host of your Grocy installation}"
cd "$task_dir"

for command_name in python3 ssh scp shasum; do
  command -v "$command_name" >/dev/null || {
    printf 'Required command is missing: %s\n' "$command_name" >&2
    exit 1
  }
done
# An SSH destination cannot be an option. Paths and commands are never accepted.
case "$deploy_host" in
  -*|*[!a-zA-Z0-9_.@-]*|'') printf 'Invalid SSH host.\n' >&2; exit 1 ;;
esac

python3 build_theme.py
for hook_name in custom_css.html custom_js.html; do
  test -s "theme/$hook_name" || { printf 'Missing hook: %s\n' "$hook_name" >&2; exit 1; }
done
css_hash="$(shasum -a 256 theme/custom_css.html)"
css_hash="${css_hash%% *}"
js_hash="$(shasum -a 256 theme/custom_js.html)"
js_hash="${js_hash%% *}"
run_id="prism-$(date -u +%Y%m%dT%H%M%SZ)-$(python3 -c 'import secrets; print(secrets.token_hex(8))')"

# run_id and hashes contain only generated ASCII alphanumerics and hyphens.
# Remote paths are resolved from the remote user's HOME, never local HOME.
remote_stage="$(ssh "$deploy_host" "/bin/bash -s -- '$run_id'" <<'REMOTE_PREPARE'
set -euo pipefail
run_id="$1"
case "$run_id" in prism-*[!a-zA-Z0-9-]*|'') exit 1 ;; prism-*) ;; *) exit 1 ;; esac
root="$HOME/Library/Application Support/Grocy"
data="$root/data"
rollback="$root/theme-rollbacks/$run_id"
stage="$data/.$run_id"
test -d "$data"
for hook_name in custom_css.html custom_js.html; do
  if test -L "$data/$hook_name"; then
    printf 'Refusing to replace a symlink: %s\n' "$data/$hook_name" >&2
    exit 1
  fi
  if test -e "$data/$hook_name" && ! test -f "$data/$hook_name"; then
    printf 'Hook is not a regular file: %s\n' "$data/$hook_name" >&2
    exit 1
  fi
done
backup_json="$(/opt/homebrew/bin/python3 "$root/scripts/backup.py")"
/opt/homebrew/bin/python3 -c 'import json,sys; result=json.load(sys.stdin); assert result.get("restore_integrity") == "ok", "Backup verification failed"' <<< "$backup_json"
printf 'Verified backup: %s\n' "$backup_json" >&2
umask 077
mkdir -p "$root/theme-rollbacks"
mkdir "$rollback"
printf '%s\n' "$backup_json" > "$rollback/backup.json"
for hook_name in custom_css.html custom_js.html; do
  if test -f "$data/$hook_name"; then
    cp -p "$data/$hook_name" "$rollback/$hook_name"
  else
    : > "$rollback/$hook_name.absent"
  fi
done
mkdir "$stage"
printf 'Previous hooks: %s\n' "$rollback" >&2
printf '%s\n' "$stage"
REMOTE_PREPARE
)"
case "$remote_stage" in
  */Library/\ Application\ Support/Grocy/data/."$run_id") ;;
  *) printf 'Unexpected remote staging path; nothing uploaded.\n' >&2; exit 1 ;;
esac

cleanup_stage() {
  local exit_status=$?
  trap - EXIT
  # Remove only this deployment's two staged hooks, then its empty directory.
  ssh "$deploy_host" "/bin/bash -s -- '$run_id'" <<'REMOTE_CLEANUP' || true
set -eu
run_id="$1"
case "$run_id" in prism-*[!a-zA-Z0-9-]*|'') exit 1 ;; prism-*) ;; *) exit 1 ;; esac
stage="$HOME/Library/Application Support/Grocy/data/.$run_id"
if test -d "$stage" && ! test -L "$stage"; then
  rm -f "$stage/custom_css.html" "$stage/custom_js.html"
  rmdir "$stage" 2>/dev/null || true
fi
REMOTE_CLEANUP
  exit "$exit_status"
}
trap cleanup_stage EXIT

# Modern scp uses SFTP, which accepts the quoted literal path containing spaces.
scp theme/custom_css.html theme/custom_js.html "$deploy_host:$remote_stage/"

ssh "$deploy_host" "/bin/bash -s -- '$run_id' '$css_hash' '$js_hash'" <<'REMOTE_INSTALL'
set -euo pipefail
run_id="$1"
expected_css="$2"
expected_js="$3"
case "$run_id" in prism-*[!a-zA-Z0-9-]*|'') exit 1 ;; prism-*) ;; *) exit 1 ;; esac
for expected_hash in "$expected_css" "$expected_js"; do
  case "$expected_hash" in *[!a-f0-9]*|'') exit 1 ;; esac
  test "${#expected_hash}" -eq 64
done
root="$HOME/Library/Application Support/Grocy"
data="$root/data"
rollback="$root/theme-rollbacks/$run_id"
stage="$data/.$run_id"
installing=0

sha256() {
  local hash_output
  hash_output="$(shasum -a 256 "$1")"
  printf '%s' "${hash_output%% *}"
}
restore_on_failure() {
  local exit_status=$?
  trap - EXIT HUP INT TERM
  if test "$installing" -eq 1; then
    printf 'Installation failed; restoring the previous theme hooks.\n' >&2
    for hook_name in custom_css.html custom_js.html; do
      if test -f "$rollback/$hook_name"; then
        restore_temp="$data/.$run_id-$hook_name.restore"
        if ! cp -p "$rollback/$hook_name" "$restore_temp" || ! mv -f "$restore_temp" "$data/$hook_name"; then
          printf 'Automatic restore failed for %s; recover it from %s.\n' "$hook_name" "$rollback" >&2
          exit_status=1
        fi
      elif test -f "$rollback/$hook_name.absent"; then
        if ! rm -f "$data/$hook_name"; then exit_status=1; fi
      else
        printf 'Missing restore record for %s in %s.\n' "$hook_name" "$rollback" >&2
        exit_status=1
      fi
    done
  fi
  exit "$exit_status"
}
trap restore_on_failure EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

test "$(sha256 "$stage/custom_css.html")" = "$expected_css"
test "$(sha256 "$stage/custom_js.html")" = "$expected_js"
chmod 0644 "$stage/custom_css.html" "$stage/custom_js.html"
installing=1
mv -f "$stage/custom_css.html" "$data/custom_css.html"
mv -f "$stage/custom_js.html" "$data/custom_js.html"
test "$(sha256 "$data/custom_css.html")" = "$expected_css"
test "$(sha256 "$data/custom_js.html")" = "$expected_js"
installing=0
printf 'Deployed theme checksums:\n'
shasum -a 256 "$data/custom_css.html" "$data/custom_js.html"
printf 'Theme rollback directory: %s\n' "$rollback"
REMOTE_INSTALL
