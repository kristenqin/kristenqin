#!/bin/bash

set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_REPO="$(cd "${SCRIPT_DIR}/.." && pwd)"

DRY_RUN=0
TARGET_DATE=""
COMMIT_MESSAGE="chore: keep profile activity current"

usage() {
  cat <<'EOF'
Usage: ./scripts/keep-profile-streak.sh [options]

Options:
  --date YYYY-MM-DD   Override the contribution date.
  --dry-run           Prepare the change locally in a temporary clone without pushing.
  --message TEXT      Override the commit message.
  --help              Show this help message.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      TARGET_DATE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --message)
      COMMIT_MESSAGE="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${TARGET_DATE}" ]]; then
  TARGET_DATE="$(date +%F)"
fi

if ! [[ "${TARGET_DATE}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "Invalid date format: ${TARGET_DATE}. Expected YYYY-MM-DD." >&2
  exit 1
fi

REMOTE_URL="$(git -C "${SOURCE_REPO}" remote get-url origin)"
DEFAULT_BRANCH="$(git -C "${SOURCE_REPO}" branch --show-current)"
AUTHOR_NAME="$(git -C "${SOURCE_REPO}" config --get user.name || true)"
AUTHOR_EMAIL="$(git -C "${SOURCE_REPO}" config --get user.email || true)"

if [[ -z "${REMOTE_URL}" ]]; then
  echo "Could not resolve origin remote for ${SOURCE_REPO}." >&2
  exit 1
fi

if [[ -z "${DEFAULT_BRANCH}" ]]; then
  DEFAULT_BRANCH="main"
fi

if [[ -z "${AUTHOR_NAME}" || -z "${AUTHOR_EMAIL}" ]]; then
  echo "Git user.name or user.email is missing in ${SOURCE_REPO}." >&2
  echo "Configure them first so GitHub can attribute the contribution correctly." >&2
  exit 1
fi

RUN_TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %z')"
GIT_TIMESTAMP="$(date '+%Y-%m-%dT%H:%M:%S%z')"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/profile-streak.XXXXXX")"
WORKTREE_DIR="${TMP_DIR}/repo"
ACTIVITY_FILE=".profile-activity.log"

cleanup() {
  rm -rf "${TMP_DIR}"
}

trap cleanup EXIT

echo "Cloning ${REMOTE_URL} into a temporary worktree..."
git clone --quiet --branch "${DEFAULT_BRANCH}" "${REMOTE_URL}" "${WORKTREE_DIR}"

cd "${WORKTREE_DIR}"

cat > "${ACTIVITY_FILE}" <<EOF
last_run_date=${TARGET_DATE}
last_run_timestamp=${RUN_TIMESTAMP}
source_repo=${REMOTE_URL}
EOF

git config user.name "${AUTHOR_NAME}"
git config user.email "${AUTHOR_EMAIL}"

git add "${ACTIVITY_FILE}"

if git diff --cached --quiet; then
  echo "No changes detected; nothing to commit."
  exit 0
fi

if [[ "${DRY_RUN}" == "1" ]]; then
  echo "Dry run complete. Prepared change:"
  git diff --cached -- "${ACTIVITY_FILE}"
  exit 0
fi

echo "Creating commit on ${DEFAULT_BRANCH} for ${TARGET_DATE}..."
GIT_AUTHOR_DATE="${GIT_TIMESTAMP}" \
GIT_COMMITTER_DATE="${GIT_TIMESTAMP}" \
git commit -m "${COMMIT_MESSAGE}" >/dev/null

echo "Pushing commit to origin/${DEFAULT_BRANCH}..."
git push origin "${DEFAULT_BRANCH}"

echo "Contribution commit pushed successfully."
