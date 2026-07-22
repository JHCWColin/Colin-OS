from __future__ import annotations

from pathlib import Path


DEFAULT_BRAND = {
    "COLIN_BRAND_NAME": "Colin OS",
    "COLIN_THEME_VARIANT": "dark",
    "COLIN_ACCENT_COLOR": "#00c2ff",
    "COLIN_BACKGROUND_COLOR": "#06121f",
    "COLIN_SURFACE_COLOR": "#0c1d2b",
    "COLIN_TEXT_COLOR": "#e6f2ff",
}


def load_brand(path: str | Path = "/etc/colinos/brand.env") -> dict[str, str]:
    brand = dict(DEFAULT_BRAND)
    env_path = Path(path)

    if not env_path.exists():
        return brand

    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, value = line.split("=", 1)
        brand[key.strip()] = value.strip().strip('"').strip("'")

    return brand


def build_stylesheet(brand: dict[str, str]) -> str:
    background = brand["COLIN_BACKGROUND_COLOR"]
    surface = brand["COLIN_SURFACE_COLOR"]
    text = brand["COLIN_TEXT_COLOR"]
    accent = brand["COLIN_ACCENT_COLOR"]

    return f"""
QWidget {{
    background-color: {background};
    color: {text};
    font-family: "Noto Sans", "DejaVu Sans", sans-serif;
    font-size: 10pt;
}}
QMainWindow {{
    background-color: {background};
}}
QFrame#Card {{
    background-color: {surface};
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 16px;
}}
QLabel#HeroTitle {{
    font-size: 24pt;
    font-weight: 700;
}}
QLabel#SectionTitle {{
    font-size: 12pt;
    font-weight: 600;
}}
QPushButton {{
    background-color: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 10px 14px;
}}
QPushButton:hover {{
    border-color: {accent};
}}
QPushButton#PrimaryButton {{
    background-color: {accent};
    color: #08131f;
    border-color: {accent};
    font-weight: 700;
}}
QListWidget, QTextEdit, QPlainTextEdit, QTableWidget {{
    background-color: rgba(0, 0, 0, 0.18);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
}}
QHeaderView::section {{
    background-color: {surface};
    color: {text};
    border: none;
    padding: 8px;
}}
"""
