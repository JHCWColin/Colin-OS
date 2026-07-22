#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PyQt6.QtWidgets import QApplication, QLabel, QMessageBox

COMMON_DIR = Path(__file__).resolve().parents[1] / "common"
if str(COMMON_DIR) not in sys.path:
    sys.path.insert(0, str(COMMON_DIR))

from colinos_app.framework import ColinWindow
from colinos_app.system import launch


FIRST_RUN_SENTINEL = Path.home() / ".config" / "colinos" / "first-run-complete"


class ColinWelcomeWindow(ColinWindow):
    def __init__(self) -> None:
        super().__init__(
            "Colin Welcome",
            "Welcome to Colin OS",
            "Your Ubuntu 24.04 LTS based development desktop is ready. "
            "This first version focuses on a stable KDE Plasma base, official repositories, "
            "and a maintainable build pipeline.",
        )
        self.setObjectName("ColinWelcomeWindow")
        self._build_overview()
        self._build_quick_actions()

    def _build_overview(self) -> None:
        _, layout = self.add_card(
            "What is included",
            "Colin OS currently targets software development, AI app development, "
            "Electron, Kotlin, web work, and content creation. The base image keeps "
            "close compatibility with Ubuntu while adding Colin OS specific tooling and branding.",
        )
        details = QLabel(
            "Highlights: KDE Plasma, official Ubuntu repositories, live-build ISO automation, "
            "and placeholder system utilities for updates, settings, and developer diagnostics."
        )
        details.setWordWrap(True)
        details.setStyleSheet("color: rgba(230, 242, 255, 0.78);")
        layout.addWidget(details)

    def _build_quick_actions(self) -> None:
        _, layout = self.add_card(
            "Quick actions",
            "Use these shortcuts to move around the first Colin OS toolset.",
        )

        open_terminal = self.make_button("Open Terminal", primary=True)
        open_updates = self.make_button("Open Update Center")
        open_settings = self.make_button("Open Settings")
        open_toolbox = self.make_button("Open Toolbox")

        open_terminal.clicked.connect(lambda: self._launch(["konsole"]))
        open_updates.clicked.connect(lambda: self._launch(["colin-update-center"]))
        open_settings.clicked.connect(lambda: self._launch(["colin-settings"]))
        open_toolbox.clicked.connect(lambda: self._launch(["colin-toolbox"]))

        finish = self.make_button("Start Using Colin OS")
        finish.clicked.connect(self._finish_first_run)

        layout.addWidget(self.button_row(open_terminal, open_updates, open_settings, open_toolbox))
        layout.addWidget(self.button_row(finish))

    def _launch(self, command: list[str]) -> None:
        success, error = launch(command)
        if not success:
            QMessageBox.warning(self, "Launch failed", error)

    def _finish_first_run(self) -> None:
        FIRST_RUN_SENTINEL.parent.mkdir(parents=True, exist_ok=True)
        FIRST_RUN_SENTINEL.write_text("completed\n", encoding="utf-8")
        self.close()

    def closeEvent(self, event) -> None:  # type: ignore[override]
        FIRST_RUN_SENTINEL.parent.mkdir(parents=True, exist_ok=True)
        if not FIRST_RUN_SENTINEL.exists():
            FIRST_RUN_SENTINEL.write_text("completed\n", encoding="utf-8")
        super().closeEvent(event)


def main() -> int:
    app = QApplication(sys.argv)
    window = ColinWelcomeWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
