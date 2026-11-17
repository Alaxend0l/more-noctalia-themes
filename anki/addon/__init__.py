"""Noctalia theme for Anki (companion of the Noctalia template).

Reads noctalia.qss (Qt chrome) once at startup and injects noctalia.css
(all web views) at content-set time. There is deliberately no reload
logic: Noctalia regenerates the two files when the palette changes, and
the new colors take effect at the next Anki start.
"""

import json
import os
import re

from aqt import mw
from aqt.gui_hooks import main_window_did_init, webview_will_set_content
from aqt.qt import QColor

_HERE = os.path.dirname(os.path.abspath(__file__))


def _read(name):
    try:
        with open(os.path.join(_HERE, name), "r", encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


_CSS = _read("noctalia.css")
_QSS = _read("noctalia.qss")
_CANVAS = ""
_m = re.search(r"--canvas:\s*([^;!]+)", _CSS)
if _m:
    _CANVAS = _m.group(1).strip()


def _apply_qss() -> None:
    if _QSS.strip():
        try:
            mw.app.setStyleSheet(_QSS)
        except Exception:  # a broken QSS must never brick the app
            pass


def _inject_theme(web_content, web_view) -> None:
    # Paint the webview background before the page loads: avoids the
    # white flash on dark palettes.
    if _CANVAS:
        try:
            web_view.webview.page().setBackgroundColor(QColor(_CANVAS))
        except Exception:
            pass
    if not _CSS.strip():
        return
    js = (
        "(function(){if(document.getElementById('noctalia-css')){return};"
        "var s=document.createElement('style');s.id='noctalia-css';"
        "s.textContent=" + json.dumps(_CSS) + ";"
        "document.documentElement.appendChild(s);})();"
    )
    web_view.evalOnLoad(js)


main_window_did_init.append(_apply_qss)
webview_will_set_content.append(_inject_theme)
