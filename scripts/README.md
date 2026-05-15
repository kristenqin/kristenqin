# Profile Streak Scripts

These scripts keep a daily GitHub contribution alive for the profile repository without touching your current local worktree.

## Scripts

### `keep-profile-streak.sh`

Clones the profile repository into a temporary directory, updates `.profile-activity.log`, creates a commit with your configured Git identity, and pushes it to the default branch.

Usage:

```bash
./scripts/keep-profile-streak.sh
./scripts/keep-profile-streak.sh --dry-run
./scripts/keep-profile-streak.sh --date 2026-05-15
```

Notes:

- It reads `origin`, `user.name`, and `user.email` from this repository.
- Your `user.email` must be verified on GitHub, otherwise the contribution may not appear on the graph.
- Because it works in a temporary clone, it does not interfere with local uncommitted changes in this repo.

### `install-profile-streak-launchd.sh`

Installs a daily `launchd` job on macOS that runs the streak script automatically.

Usage:

```bash
./scripts/install-profile-streak-launchd.sh
./scripts/install-profile-streak-launchd.sh --hour 22 --minute 15
```

After installation, the job will run every day at the configured local time.

## Practical Limitations

- The Mac still needs to be powered on and able to reach GitHub at the scheduled time.
- The push needs working GitHub authentication on this machine.

## GitHub-Hosted Automation

This repository also includes `.github/workflows/profile-streak.yml`, which runs on GitHub every day at `22:05` China Standard Time (`14:05 UTC`).

To enable it:

1. Create a GitHub personal access token that can write to this repository.
   A fine-grained token with repository `Contents: Read and write` is enough for this workflow.
2. Save it in this repository as the secret `PROFILE_STREAK_PAT`.
3. Make sure GitHub contribution settings include private contributions if this repository is private.

Notes:

- The workflow commits `.profile-activity.log` using your GitHub noreply email format so the contribution can be attributed to your account without exposing a personal email in the repo.
- This GitHub-hosted flow keeps working even when your Mac is off.
- If the Actions log shows `could not read Username for 'https://github.com': terminal prompts disabled`, it usually means `PROFILE_STREAK_PAT` is missing or invalid.
