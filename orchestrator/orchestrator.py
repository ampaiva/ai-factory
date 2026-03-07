import yaml
import subprocess
import os
import sys

SOLVE = "--solve" in sys.argv

with open("config/repos.yaml") as f:
    config = yaml.safe_load(f)

for repo in config["repositories"]:

    path = f"repos/{repo['name']}"

    if not os.path.exists(os.path.join(path, ".git")):
        r = subprocess.run(["gh", "repo", "clone", repo["repo"], path])
        if r.returncode != 0:
            print(f"[ERROR] clone failed for {repo['name']}")
            continue

    r = subprocess.run(["gh", "repo", "sync"], cwd=path)
    if r.returncode != 0:
        print(f"[ERROR] repo sync failed for {repo['name']}")
    result = subprocess.run(
        ["gh", "issue", "list"],
        cwd=path,
        capture_output=True,
        text=True
    )

    print(repo["name"])
    print(result.stdout)
    if result.returncode != 0:
        print(f"[ERROR] gh issue list failed (exit {result.returncode}):")
        print(result.stderr)

    if SOLVE:
        milestone_result = subprocess.run(
            ["gh", "api", "repos/:owner/:repo/milestones",
             "--jq", "[.[] | select(.state==\"open\" and .open_issues > 0)] | sort_by(-.open_issues) | .[0].title"],
            cwd=path, capture_output=True, text=True
        )
        milestone = milestone_result.stdout.strip()
        if milestone:
            print(f"[{repo['name']}] Solving milestone: {milestone}")
            subprocess.run(["/workspace/scripts/solve-milestone.sh", milestone], cwd=path)
        else:
            print(f"[{repo['name']}] No open milestones with issues. Skipping.")