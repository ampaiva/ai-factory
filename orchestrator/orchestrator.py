import yaml
import subprocess
import os

with open("config/repos.yaml") as f:
    config = yaml.safe_load(f)

for repo in config["repositories"]:

    path = f"/repos/{repo['name']}"

    if not os.path.exists(path):
        r = subprocess.run(["git", "clone", repo["url"], path])
        if r.returncode != 0:
            print(f"[ERROR] git clone failed for {repo['name']}")
            continue

    r = subprocess.run(["git", "-C", path, "pull"])
    if r.returncode != 0:
        print(f"[ERROR] git pull failed for {repo['name']}")

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