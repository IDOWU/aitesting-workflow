# Linux Health Check

A small, read-only Bash script that reports root filesystem disk usage, memory,
CPU load averages, hostname, kernel/architecture, and the report time. It does
not change system settings, create files, or need root privileges.

## Requirements

- Linux with Bash.
- The `df`, `free`, `hostname`, `uname`, and `date` commands.
- Read access to `/proc/loadavg`.

`free` is commonly provided by the `procps` package. If it is missing, the
script reports the problem and continues checking the other information.

## Read the script

- `#!/usr/bin/env bash` asks the environment to find and run Bash.
- `set -u` treats use of an unset variable as an error, helping catch typos.
- `set -o pipefail` makes a pipeline fail if any command in it fails. The script
  does not currently use pipelines, but this is a useful defensive Bash setting.
- `errors=0` starts a counter for problems found while collecting information.
- `report_error` writes a clear message to standard error (`>&2`) and increases
  the error count. It does not hide failures.
- `check_disk` checks that `df` exists, then runs `df -hP /`. `df` reports
  filesystem space; `-h` uses readable units, `-P` requests a predictable
  one-line-per-filesystem format, and `/` selects the root filesystem. A
  missing command or failed report is recorded as an error.
- `check_memory` checks for `free`, then runs `free -h`. This shows memory in
  readable units without changing anything.
- `check_cpu_load` verifies `/proc/loadavg` can be read, then Bash's `read`
  builtin gets the first three values: the 1-, 5-, and 15-minute load averages.
  The underscore receives remaining fields that the script does not use. Load
  average reflects runnable and waiting work; it is not CPU utilization as a
  percentage.
- `check_system_info` runs `hostname` for the machine name, `uname -srmo` for
  kernel, release, machine, and operating-system information, and `date` for
  the report time. Each command is checked and its failure is reported.
- The final `if` exits with status `1` if any checks failed; otherwise, the
  script prints a success message and exits with status `0`.

The script uses `printf` for formatted output, `command -v` to check whether a
command is available, and Bash's `[[ ... ]]` and `(( ... ))` conditional syntax.
It only reads system information.

## Test it safely

Run these commands from the project directory on a Linux machine. Review them
first; they are not run automatically.

1. `bash -n ./health-check.sh`

   Bash parses the script for syntax errors without running its checks.

2. `bash ./health-check.sh`

   Runs the read-only report through Bash, so no executable-file permission is
   needed. It prints a nonzero exit status if one or more checks cannot run.

3. Optional: `shellcheck ./health-check.sh`

   If ShellCheck is already installed, it performs static linting and does not
   run the health checks. Do not install anything unless you choose to.

No test above needs `sudo`. The script intentionally does not fill disks,
consume memory or CPU, or modify system configuration. For a test of error
handling, use a test environment where a required command is unavailable rather
than renaming or removing a system command.

## Save it to GitHub

First, create an empty repository on GitHub in your browser. Do not initialize
it with a README or license, since this project already has a README. Then run
the following from this project's directory, replacing the URL with the HTTPS
URL for your own repository:

1. `git init -b main`

   Starts a Git repository in the current directory and names its initial
   branch `main`.

2. `git status`

   Shows which files Git sees and whether they are staged or committed.

3. `git add health-check.sh README.md`

   Stages only the two project files for the next commit.

4. `git diff --cached`

   Lets you review exactly what is staged before saving it in Git history.

5. `git commit -m "Add Linux health check script"`

   Creates a local commit with a short description.

6. `git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git`

   Adds your GitHub repository as the remote named `origin`. Replace the
   placeholder URL; do not put a password or access token in the URL.

7. `git push -u origin main`

   Publishes the `main` branch to GitHub and configures it as the upstream for
   future pushes. GitHub may ask you to authenticate using its normal browser
   or credential-manager flow.

If Git reports that `origin` already exists, inspect it with
`git remote -v` before deciding what to do; do not overwrite a remote blindly.
After the first push, `git status` checks whether your local branch is up to
date.
