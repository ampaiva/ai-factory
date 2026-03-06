import subprocess

print("AI Factory starting...")

result = subprocess.run(
    ["gh", "issue", "list"],
    capture_output=True,
    text=True
)

print("Open issues:")
print(result.stdout)