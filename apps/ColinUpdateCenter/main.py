#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PyQt6.QtWidgets import QApplication, QLabel, QMessageBox, QPlainTextEdit

COMMON_DIR = Path(__file__).resolve().parents[1] / "common"
if str(COMMON_DIR) not in sys.path:
    sys.path.insert(0, str(COMMON_DIR))

from colinos_app.framework import ColinWindow
from colinos_app.system import command_exists, launch, run_version


class ColinUpdateCenterWindow(ColinWindow):
    def __init__(self) -> None:
        super().__init__(
            "Colin Update Center",
            "Colin Update Center",
            "The first version delegates package management to Ubuntu and KDE tooling instead of implementing a custom package manager frontend.",
        )
        self._build_status()
        self._build_actions()

    def _build_status(self) -> None:
        _, layout = self.add_card(
            "Update backend",
            "Colin OS currently uses the native Ubuntu packaging stack and KDE Discover for the user-facing update workflow.",
        )

        status_text = QPlainTextEdit()
        status_text.setReadOnly(True)
        status_text.setPlainText(
            "\n".join(
                [
                    f"plasma-discover: {'available' if command_exists('plasma-discover') else 'not found'}",
                    f"pkcon: {'available' if command_exists('pkcon') else 'not found'}",
                    f"packagekitd: {'available' if command_exists('packagekitd') else 'not found'}",
                    f"APT policy: {run_version(['apt', '--version'])}",
                ]
            )
        )
        layout.addWidget(status_text)

    def _build_actions(self) -> None:
        _, layout = self.add_card(
            "Actions",
            "Use Discover for normal updates. The PackageKit refresh action is provided as a lightweight troubleshooting tool.",
        )

        open_discover = self.make_button("Open Discover Updates", primary=True)
        refresh_cache = self.make_button("Refresh Package Metadata")
        show_help = self.make_button("Show Manual Commands")

        open_discover.clicked.connect(self._open_discover_updates)
        refresh_cache.clicked.connect(self._refresh_metadata)
        show_help.clicked.connect(self._show_manual_commands)

        layout.addWidget(self.button_row(open_discover, refresh_cache, show_help))

        note = QLabel(
            "This first version intentionally avoids replacing Ubuntu's update logic. "
            "It acts as a Colin OS oriented entry point instead."
        )
        note.setWordWrap(True)
        note.setStyleSheet("color: rgba(230, 242, 255, 0.78);")
        layout.addWidget(note)

    def _open_discover_updates(self) -> None:
        for command in (["plasma-discover", "--mode", "update"], ["plasma-discover"]):
            success, _ = launch(command)
            if success:
                return
        QMessageBox.warning(self, "Discover not available", "Unable to launch plasma-discover.")

    def _refresh_metadata(self) -> None:
        success, error = launch(["pkcon", "refresh"])
        if not success:
            QMessageBox.warning(self, "Refresh failed", error)

    def _show_manual_commands(self) -> None:
        QMessageBox.information(
            self,
            "Manual update commands",
            "GUI path:\n"
            "  plasma-discover --mode update\n\n"
            "CLI refresh:\n"
            "  pkcon refresh\n\n"
            "APT fallback:\n"
            "  sudo apt update\n"
            "  sudo apt full-upgrade",
        )


def main() -> int:
    app = QApplication(sys.argv)
    window = ColinUpdateCenterWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
