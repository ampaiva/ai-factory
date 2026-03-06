import yaml
import subprocess
import os

with open("config/repos.yaml") as f:
    config = yaml.safe_load(f)

for repo in config["repositories"]:

    path = f"/repos/{repo['name']}"

    if not os.path.exists(path):

        subprocess.run([
            "git", "clone", repo["url"], path
        ])

    subprocess.run(
        ["git", "-C", path, "pull"]
    )

    result = subprocess.run(
        ["gh", "issue", "list"],
        cwd=path,
        capture_output=True,
        text=True
    )

    print(repo["name"])
    print(result.stdout)