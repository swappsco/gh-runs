# 🛠️ gh-tools

A collection of command-line tools built with the GitHub CLI to automate and manage repositories and workflows at scale.

## 📜 Available Scripts

- [`gh_actions_queue.sh`](#️-gh_actions_queuesh) — Manage and cancel GitHub Actions workflow runs across repos or entire orgs.
- [`gh_archive.sh`](#-gh_archivesh) — List and archive inactive repositories in an organization.

## ⚙️ gh_actions_queue.sh

This Bash script helps manage **cancellable GitHub Actions workflow runs** (`queued` and `in_progress`) for a specific repository or an entire GitHub organization using the GitHub CLI.

It can:

- List cancellable workflow runs
- Cancel up to a defined number of them
- Run in **dry-run** mode for safety
- Output detailed logs with `--debug`

---

## 🧰 Requirements

- [`gh` CLI](https://cli.github.com/) installed and authenticated
- `jq` installed
- `bash` (compatible with most POSIX shells)

---

## 🚀 Usage

```bash
./gh_actions_queue.sh <target> <action> [limit] [--debug] [--dry-run]
```

### Parameters

| Argument     | Description                                                                          |
|--------------|--------------------------------------------------------------------------------------|
| `<target>`   | The target GitHub repo (`owner/repo`) or organization (`owner`)                     |
| `<action>`   | `list` or `cancel`                                                                   |
| `[limit]`    | (Optional) Max number of workflow runs to cancel per repo (default: `20`)            |
| `--debug`    | (Optional) Enables verbose output (commands, per-repo info, run IDs)                |
| `--dry-run`  | (Optional) Show what would be cancelled without performing any actual cancellation  |

---

## 🧪 Examples

### List cancellable runs for a repo

```bash
./gh_actions_queue.sh swappsco/dejusticia list
```

### Cancel up to 20 cancellable runs for a repo

```bash
./gh_actions_queue.sh swappsco/dejusticia cancel
```

### Cancel up to 50 for an organization (all repos)

```bash
./gh_actions_queue.sh swappsco cancel 50
```

### Preview cancel actions without actually cancelling

```bash
./gh_actions_queue.sh swappsco cancel 50 --dry-run
```

### Combine dry-run and debug

```bash
./gh_actions_queue.sh swappsco cancel 50 --dry-run --debug
```

---

## 🧾 Output

At the end, the script prints a summary like this:

```
📋 Repositories with cancellable runs:
swappsco/ncarb – https://github.com/swappsco/ncarb/actions
swappsco/wp-swappscom – https://github.com/swappsco/wp-swappscom/actions
```

---

## ⚠️ Notes

- Only `queued` and `in_progress` workflow runs are considered cancellable.
- The GitHub CLI must be authenticated with appropriate access to the repos.
- If using org-wide mode, ensure your token has visibility into all relevant repositories.

---

## 📦 gh_archive.sh

This Bash script helps identify and optionally archive GitHub repositories in an organization that haven't been updated since a specified date.

It can:

- List repositories not updated since a given date
- Optionally archive them in bulk
- Exclude repositories based on keywords
- Skip archive confirmation with a flag

---

### 🧰 Requirements

- [`gh` CLI](https://cli.github.com/) installed and authenticated
- `jq` installed
- `bash` (compatible with most POSIX shells)

---

### 🚀 Usage

```bash
./gh_archive.sh <org> <cutoff-date> [exclude_keywords] [--yes]
```

### Parameters

| Argument            | Description                                                                 |
|---------------------|-----------------------------------------------------------------------------|
| `<org>`             | The GitHub organization name                                                |
| `<cutoff-date>`     | Date in `YYYY-MM-DD` format. Repos not updated since will be listed         |
| `[exclude_keywords]`| (Optional) Comma-separated keywords to exclude matching repo names          |
| `--yes`             | (Optional) Automatically archive without asking for confirmation            |

---

### 🧪 Examples

List repos not updated since Jan 1, 2022:

```bash
./gh_archive.sh swappsco 2022-01-01
```

Exclude repos with names containing `infra` or `ansible`:

```bash
./gh_archive.sh swappsco 2022-01-01 infra,ansible
```

Automatically archive all matching repos:

```bash
./gh_archive.sh swappsco 2022-01-01 infra,ansible --yes
```

---

### ✅ Output

The script will:

- List outdated repositories
- Optionally archive them
- Verify each archive status with checkmarks ✅ / ❌
