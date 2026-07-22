#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import QApplication, QLabel, QTableWidget, QTableWidgetItem

COMMON_DIR = Path(__file__).resolve().parents[1] / "common"
if str(COMMON_DIR) not in sys.path:
    sys.path.insert(0, str(COMMON_DIR))

from colinos_app.framework import ColinWindow
from colinos_app.system import run_version


TOOLS = [
    ("Git", ["git", "--version"]),
    ("Node.js", ["node", "--version"]),
    ("npm", ["npm", "--version"]),
    ("Python", ["python3", "--version"]),
    ("pip", ["python3", "-m", "pip", "--version"]),
    ("Java", ["java", "--version"]),
]


class ColinToolboxWindow(ColinWindow):
    def __init__(self) -> None:
        super().__init__(
            "Colin Toolbox",
            "Colin Toolbox",
            "A lightweight diagnostics surface for the development toolchain bundled with Colin OS.",
        )
        self._build_table()

    def _build_table(self) -> None:
        _, layout = self.add_card(
            "Detected toolchain versions",
            "These values are resolved from the current runtime environment. They are intended for quick verification after install.",
        )

        table = QTableWidget(len(TOOLS), 2)
        table.setHorizontalHeaderLabels(["Tool", "Detected version"])
        table.verticalHeader().setVisible(False)
        table.horizontalHeader().setStretchLastSection(True)
        table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        table.setSelectionMode(QTableWidget.SelectionMode.NoSelection)

        for row, (name, command) in enumerate(TOOLS):
            version = run_version(command)
            name_item = QTableWidgetItem(name)
            version_item = QTableWidgetItem(version)
            version_item.setTextAlignment(Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter)
            table.setItem(row, 0, name_item)
            table.setItem(row, 1, version_item)

        layout.addWidget(table)

        footnote = QLabel(
            "Future versions can extend this utility with SDK detection, environment health checks, and repository mirror diagnostics."
        )
        footnote.setWordWrap(True)
        footnote.setStyleSheet("color: rgba(230, 242, 255, 0.78);")
        layout.addWidget(footnote)


def main() -> int:
    app = QApplication(sys.argv)
    window = ColinToolboxWindow()
    window.show()
    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
