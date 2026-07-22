#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PyQt6.QtWidgets import QApplication, QLabel, QListWidget, QListWidgetItem, QTextEdit, QWidget, QHBoxLayout

COMMON_DIR = Path(__file__).resolve().parents[1] / "common"
if str(COMMON_DIR) not in sys.path:
    sys.path.insert(0, str(COMMON_DIR))

from colinos_app.framework import ColinWindow


SECTION_TEXT = {
    "Appearance": "This placeholder section will manage theme, wallpaper, accent color, and future Colin OS look-and-feel presets.",
    "System": "This placeholder section is reserved for Colin OS system information, release metadata, and future maintenance toggles.",
    "Development": "This placeholder section will expose developer defaults such as terminal preferences, SDK setup guides, and repository policies.",
    "Updates": "This placeholder section will integrate Colin Update Center preferences and release channel policy once update workflow handling is finalized.",
    "About": "Colin Settings will eventually surface branding, license details, base Ubuntu release data, and links to the project repository.",
}


class ColinSettingsWindow(ColinWindow):
    def __init__(self) -> None:
        super().__init__(
            "Colin Settings",
            "Colin Settings",
            "The first version provides the UI shell and section model. "
            "Functional settings pages will be added once Colin OS system modules are stabilized.",
        )
        self._build_shell()

    def _build_shell(self) -> None:
        _, layout = self.add_card(
            "Settings sections",
            "The categories on the left define the intended expansion path for the Colin OS control center.",
        )

        shell = QWidget()
        shell_layout = QHBoxLayout(shell)
        shell_layout.setContentsMargins(0, 0, 0, 0)
        shell_layout.setSpacing(14)

        self.section_list = QListWidget()
        self.section_list.setMinimumWidth(220)
        for name in SECTION_TEXT:
            QListWidgetItem(name, self.section_list)

        self.detail_panel = QTextEdit()
        self.detail_panel.setReadOnly(True)

        shell_layout.addWidget(self.section_list, 0)
        shell_layout.addWidget(self.detail_panel, 1)
        layout.addWidget(shell)

        footer = QLabel("The framework is intentionally modular so later versions can replace each placeholder with dedicated settings widgets.")
        footer.setWordWrap(True)
        footer.setStyleSheet("color: rgba(230, 242, 255, 0.78);")
        layout.addWidget(footer)

        self.section_list.currentTextChanged.connect(self._update_detail)
        self.section_list.setCurrentRow(0)

    def _update_detail(self, section_name: str) -> None:
        self.detail_panel.setPlainText(SECTION_TEXT.get(section_name, "Section not available."))


def main() -> int:
    app = QApplication(sys.argv)
    window = ColinSettingsWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
