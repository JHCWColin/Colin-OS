from __future__ import annotations

import shutil
import subprocess


def command_exists(command: str) -> bool:
    return shutil.which(command) is not None


def run_version(command: list[str], *, first_line_only: bool = True) -> str:
    try:
        result = subprocess.run(
            command,
            check=True,
            capture_output=True,
            text=True,
        )
    except (OSError, subprocess.CalledProcessError):
        return "Not available"

    output = (result.stdout or result.stderr).strip()
    if not output:
        return "Not available"

    if first_line_only:
        return output.splitlines()[0].strip()

    return output


def launch(command: list[str]) -> tuple[bool, str]:
    try:
        subprocess.Popen(command)
    except OSError as exc:
        return False, str(exc)
    return True, ""
