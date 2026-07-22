from __future__ import annotations

from PyQt6.QtCore import Qt
from PyQt6.QtWidgets import (
    QFrame,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QPushButton,
    QScrollArea,
    QSizePolicy,
    QVBoxLayout,
    QWidget,
)

from .brand import build_stylesheet, load_brand


class ColinWindow(QMainWindow):
    def __init__(self, app_name: str, title: str, subtitle: str) -> None:
        super().__init__()
        self.brand = load_brand()
        self.setWindowTitle(app_name)
        self.resize(1120, 760)
        self.setStyleSheet(build_stylesheet(self.brand))

        root = QWidget()
        outer_layout = QVBoxLayout(root)
        outer_layout.setContentsMargins(24, 24, 24, 24)
        outer_layout.setSpacing(18)

        hero_card = QFrame()
        hero_card.setObjectName("Card")
        hero_layout = QVBoxLayout(hero_card)
        hero_layout.setContentsMargins(22, 18, 22, 18)
        hero_layout.setSpacing(6)

        hero_title = QLabel(title)
        hero_title.setObjectName("HeroTitle")
        hero_title.setWordWrap(True)
        hero_subtitle = QLabel(subtitle)
        hero_subtitle.setWordWrap(True)
        hero_subtitle.setStyleSheet("color: rgba(230, 242, 255, 0.78);")

        hero_layout.addWidget(hero_title)
        hero_layout.addWidget(hero_subtitle)

        scroll_area = QScrollArea()
        scroll_area.setFrameShape(QFrame.Shape.NoFrame)
        scroll_area.setWidgetResizable(True)

        scroll_root = QWidget()
        self.content_layout = QVBoxLayout(scroll_root)
        self.content_layout.setContentsMargins(0, 0, 0, 0)
        self.content_layout.setSpacing(18)
        self.content_layout.addStretch(1)

        scroll_area.setWidget(scroll_root)

        outer_layout.addWidget(hero_card)
        outer_layout.addWidget(scroll_area)
        self.setCentralWidget(root)

    def add_card(self, title: str, body: str) -> tuple[QFrame, QVBoxLayout]:
        card = QFrame()
        card.setObjectName("Card")
        card.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Maximum)

        layout = QVBoxLayout(card)
        layout.setContentsMargins(20, 18, 20, 18)
        layout.setSpacing(12)

        title_label = QLabel(title)
        title_label.setObjectName("SectionTitle")
        body_label = QLabel(body)
        body_label.setWordWrap(True)
        body_label.setStyleSheet("color: rgba(230, 242, 255, 0.78);")

        layout.addWidget(title_label)
        layout.addWidget(body_label)

        self.content_layout.insertWidget(self.content_layout.count() - 1, card)
        return card, layout

    @staticmethod
    def make_button(label: str, *, primary: bool = False) -> QPushButton:
        button = QPushButton(label)
        if primary:
            button.setObjectName("PrimaryButton")
        button.setCursor(Qt.CursorShape.PointingHandCursor)
        return button

    @staticmethod
    def button_row(*buttons: QPushButton) -> QWidget:
        wrapper = QWidget()
        layout = QHBoxLayout(wrapper)
        layout.setContentsMargins(0, 0, 0, 0)
        layout.setSpacing(10)
        for button in buttons:
            layout.addWidget(button)
        layout.addStretch(1)
        return wrapper
