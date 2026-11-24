#!/usr/bin/env python3
"""Generate KelaPadUI locale files from the English source.

Usage:
    python _tools/translate_kpui_lang.py de
    python _tools/translate_kpui_lang.py fr ru
    python _tools/translate_kpui_lang.py --all

The default backend is the free Google NMT endpoint (no API key, stdlib
only). Pass --offline to use argostranslate instead; that path installs the
package and its en-><lang> model on demand.

Strings that exactly match a string in the ESO client's own language files
are taken from those files, so ESO terminology (Group Finder, Infinite
Archive, Tamriel Tomes, ...) stays consistent with the game. Everything else
is machine translated. Placeholders (<<1>>, %d, %s, ...) and newlines are
validated after every translation; a string that fails validation twice is
left in English and reported at the end.

This is a build/development helper only; ESO does not load it.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EN_PATH = ROOT / "kpui_lang" / "en.lua"
LANG_DIR = ROOT / "kpui_lang"
DEFAULT_CACHE = Path(__file__).resolve().parent / ".translation_cache.json"
DEFAULT_CLIENT_LANG_DIR = ROOT.parents[2] / "esoui-sourcecode" / "esoui" / "lang"
SUPPORTED = ("de", "fr", "ru", "jp", "es", "zh")
CAMPAIGN = ("de", "fr", "ru", "jp", "es", "zh")
# ESO names its locales by client code (kpui_lang/jp.lua is loaded through
# $(language)); the translation services use ISO codes.
BACKEND_CODES = {"jp": "ja", "zh": "zh-CN"}


def backend_code(target: str) -> str:
    return BACKEND_CODES.get(target, target)

ADD_LINE = re.compile(
    r'^(?P<indent>[ \t]*)Add\("(?P<id>KELA_[A-Z0-9_]+)"\s*,\s*'
    r'"(?P<text>(?:[^"\\]|\\.)*)"\)\s*$'
)
SAFE_ADD_LINE = re.compile(
    r'^(?P<indent>[ \t]*)Add\((?P<id>KELA_[A-Z0-9_]+)\s*,\s*'
    r'"(?P<text>(?:[^"\\]|\\.)*)"\s*,\s*0\)\s*$'
)
CLIENT_STRING = re.compile(
    r'\bSAS\(\s*(?P<id>SI_[A-Z0-9_]+)\s*,\s*'
    r'"(?P<text>(?:[^"\\]|\\.)*)"\s*,\s*\d+\s*\)'
)
TOKEN = re.compile(
    r"<<(?:(?P<prefix>[A-Za-z]):)?(?P<index>\d+)"
    r"(?:\[(?P<plural>[^\]]*)\])?>>"
)
PLAIN_TOKEN = re.compile(r"<<(?:(?:[A-Za-z]:)?\d+)>>")
PERCENT = re.compile(r"%(?:%|[-+ #0]*\d*(?:\.\d+)?[sdif])")
BRAND_TOKENS = ("KelaPadUI Enhanced", "KelaPadUI", "ESO+", "USPF")

# Hand-checked text. Applies to any string, per language, before machine
# translation; entries that are also ESO client strings need every language.
OVERRIDES = {
    # Ability bar labels: game terms from <code>_client.lua
    # (SI_INTERFACE_OPTIONS_ACTION_BAR*, SI_INTERFACE_OPTIONS_RESOURCE_BARS), kept short.
    "Ability Bar": {"de": "Fähigkeitenleiste", "fr": "Barre de compétences", "ru": "Панель способностей", "jp": "アビリティバー", "es": "Barra de habilidades", "zh": "技能栏"},
    "Ability bar enhancements": {"de": "Erweiterte Fähigkeitenleiste", "fr": "Barre de compétences améliorée", "ru": "Улучшенная панель способностей", "jp": "アビリティバー拡張", "es": "Barra de habilidades mejorada", "zh": "技能栏增强"},
    "Show stack counts": {"de": "Stapel anzeigen", "fr": "Afficher les cumuls", "ru": "Показывать стаки", "jp": "スタック数を表示", "es": "Mostrar acumulaciones", "zh": "显示层数"},
    "Expiry warning": {"de": "Ablaufwarnung", "fr": "Alerte d'expiration", "ru": "Предупреждение об окончании", "jp": "終了警告", "es": "Aviso de fin", "zh": "到期警告"},
    "Always show back row": {"de": "Alternative Leiste immer anzeigen", "fr": "Toujours afficher la rangée arrière", "ru": "Всегда показывать второй ряд", "jp": "後列を常に表示", "es": "Mostrar siempre la fila secundaria", "zh": "始终显示后排"},
    "Shows the back row for every skill on your other bar, not only while an effect is running on it. Your ultimate is left out. Needs the game's <<1>> and <<2>> options.": {
        "de": "Zeigt die hintere Reihe für jede Fertigkeit Ihrer anderen Leiste an, nicht nur, während ein Effekt läuft. Ihre ultimative Fähigkeit bleibt außen vor. Benötigt die Spieloptionen <<1>> und <<2>>.",
        "fr": "Affiche la rangée arrière pour chaque compétence de votre autre barre, pas seulement lorsqu'un effet est en cours. Votre ultime est exclu. Nécessite les options <<1>> et <<2>> du jeu.",
        "ru": "Показывает второй ряд для каждого навыка на другой панели, а не только пока на нём действует эффект. Суперспособность не включается. Требуются опции игры <<1>> и <<2>>.",
        "jp": "もう一方のバーのすべてのスキルについて、効果が発動している間だけでなく、常に後列を表示します。アルティメットは対象外です。ゲームの<<1>>と<<2>>の設定が必要です。",
        "es": "Muestra la fila secundaria para cada habilidad de tu otra barra, no solo mientras hay un efecto activo. Tu habilidad máxima queda fuera. Necesita las opciones <<1>> y <<2>> del juego.",
        "zh": "为另一栏的每项技能显示后排，而不仅仅是在其效果运行期间。终极技能不包括在内。需要开启游戏的“<<1>>”和“<<2>>”选项。",
    },
    "Raise back row": {"de": "Alternative Leiste anheben", "fr": "Rehausser la rangée arrière", "ru": "Поднять второй ряд", "jp": "後列を上げる", "es": "Subir fila secundaria", "zh": "抬高后排"},
    "Shows the thin progress bar on the back row's timer. Turn it off to remove the bar and its empty groove.": {
        "de": "Zeigt den dünnen Fortschrittsbalken am Timer der Alternativleiste an. Deaktivieren Sie ihn, um den Balken samt leerer Rille zu entfernen.",
        "fr": "Affiche la fine barre de progression du minuteur de la rangée arrière. Désactivez-la pour retirer la barre et sa rainure vide.",
        "ru": "Показывает тонкую полосу прогресса на таймере второго ряда. Выключите, чтобы убрать полосу вместе с пустым желобком.",
        "jp": "後列のタイマーに細い進行バーを表示します。オフにすると、バーと空の溝がなくなります。",
        "es": "Muestra la delgada barra de progreso del temporizador de la fila secundaria. Desactívala para quitar la barra y su ranura vacía.",
        "zh": "显示后排计时器上的细进度条。关闭后将移除进度条及其空凹槽。",
    },
    "Shows a countdown in seconds on back row skills with a running effect. Works with or without the progress bar.": {
        "de": "Zeigt für Fertigkeiten der Alternativleiste mit aktivem Effekt einen Countdown in Sekunden an. Funktioniert mit oder ohne Fortschrittsbalken.",
        "fr": "Affiche un compte à rebours en secondes sur les compétences de la rangée arrière dont l'effet est actif. Fonctionne avec ou sans la barre de progression.",
        "ru": "Показывает обратный отсчёт в секундах для навыков второго ряда с действующим эффектом. Работает с полосой прогресса и без неё.",
        "jp": "効果が発動中の後列スキルに、残り秒数のカウントダウンを表示します。進行バーの有無にかかわらず使えます。",
        "es": "Muestra una cuenta atrás en segundos en las habilidades de la fila secundaria con un efecto activo. Funciona con o sin la barra de progreso.",
        "zh": "为带有生效中效果的后排技能显示倒计时秒数。无论是否显示进度条都可使用。",
    },
    "Back row timer numbers": {"de": "Alternative Leiste: Zahlen", "fr": "Chiffres de la rangée arrière", "ru": "Цифры таймера второго ряда", "jp": "後列タイマーの数字", "es": "Números de la fila secundaria", "zh": "后排计时数字"},
    "Back row progress bar": {"de": "Alternative Leiste: Balken", "fr": "Barre de la rangée arrière", "ru": "Полоса таймера второго ряда", "jp": "後列の進行バー", "es": "Barra de la fila secundaria", "zh": "后排进度条"},
    "Attribute bar shift": {"de": "Attributsbalken verschieben", "fr": "Décaler les barres", "ru": "Сдвиг шкал характеристик", "jp": "能力バーの位置調整", "es": "Desplazar barras de atributos", "zh": "属性条位移"},
    # Ability bar master switch: machine translation drops it to English in jp/zh.
    "Adds stack counts, an expiry warning, and a taller back row to the gamepad ability bar. The back row needs the game's <<1>> and <<2>> options under <<3>>. Stays off while <<4>> or <<5>> is loaded. Requires a UI reload.": {
        "jp": "ゲームパッドのアビリティバーにスタック数、終了警告、高くした後列を追加します。後列を表示するには、「<<1>>」と「<<2>>」（<<3>>）をオンにする必要があります。<<4>>または<<5>>が読み込まれている間はオフのままです。UIの再読み込みが必要です。",
        "zh": "为手柄技能栏添加层数、到期警告和更高的后排。后排需要开启“<<1>>”和“<<2>>”（<<3>>）。加载<<4>>或<<5>>时保持关闭。需要重新加载界面。",
    },
    "Shows stack counts on both rows, including stacks the game only shows as a glow, such as <<1>> on <<2>>. When a stacking effect has an expiry, it shows as a timer.": {
        "de": "Zeigt Stapelanzahlen in beiden Reihen an, auch für Stapel, die das Spiel nur als Leuchten zeigt, etwa <<1>> bei <<2>>. Hat ein stapelnder Effekt eine Ablaufzeit, wird sie als Timer angezeigt.",
        "fr": "Affiche le nombre de cumuls sur les deux rangées, y compris ceux que le jeu ne montre que par une lueur, comme <<1>> sur <<2>>. Quand un effet cumulable a une durée, elle s'affiche comme un minuteur.",
        "ru": "Показывает число стаков в обоих рядах, в том числе тех, что игра отмечает лишь свечением, например «<<1>>» у «<<2>>». Если у накапливаемого эффекта есть срок действия, он показывается как таймер.",
        "jp": "両方の列にスタック数を表示します。<<1>>（<<2>>）のように、ゲームでは光るだけのスタックも含みます。スタック効果に期限がある場合は、タイマーとして表示します。",
        "es": "Muestra las acumulaciones en ambas filas, incluidas las que el juego solo indica con un brillo, como <<1>> en <<2>>. Si un efecto acumulable tiene vencimiento, se muestra como un temporizador.",
        "zh": "在两排技能上显示层数，包括游戏只用发光提示的层数，例如<<1>>（<<2>>）。叠加效果带有时限时，会显示为计时器。",
    },
    # Add-on status lines in setting tooltips ("Requires:", "LibX: found").
    "Requires one of": {"fr": "Nécessite l'un de", "jp": "いずれかが必要"},
    "Uses if installed": {"de": "Nutzt, falls installiert", "ru": "Использует, если установлен", "jp": "インストール時に使用", "es": "Usa si está instalado", "zh": "安装后使用"},
    "Stays off while loaded": {"de": "Bleibt aus, wenn geladen", "fr": "Désactivé si chargé", "ru": "Отключается, если загружен", "jp": "読み込まれているとオフ", "es": "Se desactiva si está cargado", "zh": "以下插件加载时关闭"},
    "found": {"ru": "найден", "jp": "検出", "es": "encontrado", "zh": "已找到"},
    "not found": {"fr": "introuvable", "ru": "не найден", "jp": "未検出", "es": "no encontrado"},
    # Panel title: "Journal" is the game's SI_MAIN_MENU_JOURNAL; "browsers" are the sets and knowledge screens.
    "Journals and Browsers": {"de": "Tagebücher und Übersichten", "fr": "Journaux et catalogues", "ru": "Журналы и каталоги", "jp": "日記とブラウザー", "es": "Diarios y catálogos", "zh": "日志与浏览器"},
    # Settings labels read as a setting, not a command to the reader.
    "Share <<1>> settings with all characters": {"de": "<<1>>-Einstellungen mit allen Charakteren teilen", "ru": "Общие настройки «<<1>>» для всех персонажей", "es": "Compartir la configuración de <<1>> con todos los personajes"},
    "Undaunted": {"de": "Unerschrockene", "fr": "Indomptables", "ru": "Неустрашимые"},
    # KELA_THOUSANDS_SEPARATOR: machine translation returns the English comma.
    ",": {"de": ".", "fr": " ", "ru": " ", "jp": ",", "es": ".", "zh": ","},
    # "character" means a player character here, not a letter.
    "<<1[$d character/$d characters]>>": {"de": "<<1[$d Charakter/$d Charaktere]>>", "fr": "<<1[$d personnage/$d personnages]>>", "ru": "<<1[$d персонаж/$d персонажей]>>", "jp": "<<1[$dキャラクター/$dキャラクター]>>", "es": "<<1[$d personaje/$d personajes]>>", "zh": "<<1[$d个角色/$d个角色]>>"},
    "<<1[$d entry/$d entries]>>": {"de": "<<1[$d Eintrag/$d Einträge]>>", "fr": "<<1[$d entrée/$d entrées]>>", "ru": "<<1[$d запись/$d записей]>>", "jp": "<<1[$d件/$d件]>>", "es": "<<1[$d entrada/$d entradas]>>", "zh": "<<1[$d 条/$d 条]>>"},
    "Idle": {"ru": "Простаивает", "jp": "待機中", "zh": "空闲"},
    # Japanese: match the client's stat wording (SI_DERIVEDSTATS*).
    "Critical": {"jp": "クリティカル", "zh": "暴击"},
    "Penetration": {"jp": "貫通", "zh": "穿透"},
    "Healing": {"jp": "回復力", "es": "Curación", "zh": "治疗"},
    "Recovery": {"jp": "再生"},
    "Normal": {"jp": "普通", "zh": "一般"},
    "Researched: <<1>>": {"jp": "研究済み: <<1>>", "zh": "已研究：<<1>>"},
    # Deal ratings agree with "oferta" in Spanish; plain adjectives in Chinese.
    "Good": {"es": "Buena", "zh": "好"},
    "Bad": {"es": "Mala", "zh": "差"},
    "Terrible": {"zh": "很差"},
    "Excellent": {"zh": "极好"},
    "Complete": {"zh": "已完成"},
    "Summary": {"zh": "总览"},
    "Sets": {"zh": "套装"},
    "<<1>> active - <<2>>": {"zh": "<<1>> 项进行中 - <<2>>"},
    # Character Knowledge: game terms from <code>_client.lua; machine
    # translation left these in English or picked the wrong sense.
    "Server": {"fr": "Serveur", "ru": "Сервер", "jp": "サーバー", "es": "Servidor", "zh": "服务器"},
    "Known": {"de": "Bekannt", "jp": "習得済み"},
    "Quality": {"jp": "品質"},
    "Characters": {"zh": "角色"},
    "Adds Character Knowledge to the KelaPadUI² menu when LibCharacterKnowledge is installed: which recipes, furnishing plans, motifs, and scribing items each character knows, with filters and the item tooltip.": {"de": "Fügt dem KelaPadUI²-Menü Character Knowledge hinzu, wenn LibCharacterKnowledge installiert ist: welche Rezepte, Einrichtungspläne, Stile und Schriftlehre-Gegenstände jeder Charakter kennt, mit Filtern und dem Gegenstands-Tooltip.", "fr": "Ajoute Character Knowledge au menu KelaPadUI² quand LibCharacterKnowledge est installé : les recettes, plans d'ameublement, styles et objets d'écriture que connaît chaque personnage, avec des filtres et l'infobulle de l'objet.", "ru": "Добавляет Character Knowledge в меню KelaPadUI², если установлена LibCharacterKnowledge: какие рецепты, инструкции для предметов обстановки, ремесленные мотивы и предметы чарописи знает каждый персонаж, с фильтрами и подсказкой предмета.", "jp": "LibCharacterKnowledgeがインストールされている場合、KelaPadUI²メニューにCharacter Knowledgeを追加します。各キャラクターが習得しているレシピ、家具の設計図、モチーフ、書記アイテムを、フィルターとアイテムのツールチップ付きで表示します。", "es": "Añade Character Knowledge al menú KelaPadUI² cuando LibCharacterKnowledge está instalado: qué recetas, planos de mobiliario, motivos y objetos de escribanía conoce cada personaje, con filtros y la descripción del objeto.", "zh": "安装LibCharacterKnowledge后，在KelaPadUI²菜单中添加Character Knowledge：显示每个角色已学会的配方、装饰品图纸、样式书和篆刻物品，并提供筛选和物品提示。"},
}


# --------------------------------------------------------------------------
# Lua string helpers
# --------------------------------------------------------------------------

def unescape_lua(value: str) -> str:
    out = []
    i = 0
    while i < len(value):
        char = value[i]
        if char == "\\" and i + 1 < len(value):
            nxt = value[i + 1]
            if nxt == "n":
                out.append("\n")
            elif nxt == "t":
                out.append("\t")
            elif nxt == "r":
                out.append("\r")
            elif nxt == '"':
                out.append('"')
            elif nxt == "\\":
                out.append("\\")
            else:
                out.append(nxt)
            i += 2
            continue
        out.append(char)
        i += 1
    return "".join(out)


def escape_lua(value: str) -> str:
    return (
        value.replace("\\", "\\\\")
        .replace('"', '\\"')
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
    )


def token_signature(value: str) -> tuple:
    tokens = []
    for match in TOKEN.finditer(value):
        plural = match.group("plural")
        tokens.append(
            (
                match.group("prefix"),
                int(match.group("index")),
                plural is not None,
                plural.count("$") if plural else 0,
                plural.count("/") if plural else 0,
            )
        )
    return (
        tuple(tokens),
        len(PERCENT.findall(value)),
        value.count("\n"),
    )


# --------------------------------------------------------------------------
# Source parsing / writing
# --------------------------------------------------------------------------

def read_lines(path: Path) -> tuple[list[str], str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        raw = handle.read()
    newline = "\r\n" if "\r\n" in raw else "\n"
    lines = raw.replace("\r\n", "\n").replace("\r", "\n").split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    return lines, newline


def parse_source(path: Path):
    lines, newline = read_lines(path)
    entries = []
    for line_number, line in enumerate(lines, start=1):
        match = ADD_LINE.match(line)
        if not match:
            if 'Add("KELA_' in line:
                raise SystemExit(
                    "Unhandled Add() line {}: {}".format(line_number, line)
                )
            continue
        entries.append(
            {
                "line": line_number,
                "id": match.group("id"),
                "text": unescape_lua(match.group("text")),
            }
        )
    if not entries:
        raise SystemExit("No KELA Add() entries found in {}".format(path))
    return lines, newline, entries


def render_locale(source_lines, newline, entries, translations, target):
    out = [
        "-- Generated from kpui_lang/en.lua by _tools/translate_kpui_lang.py.",
        "-- Do not edit by hand; regenerate with:",
        "--   python _tools/translate_kpui_lang.py {}".format(target),
        "",
    ]
    entry_by_line = {entry["line"]: entry for entry in entries}
    for line_number, line in enumerate(source_lines, start=1):
        entry = entry_by_line.get(line_number)
        if entry is None:
            if "local Add = ZO_CreateStringId" in line:
                out.append(line.replace("ZO_CreateStringId", "SafeAddString"))
            else:
                out.append(line)
            continue
        indent = ADD_LINE.match(line).group("indent")
        translated = translations[entry["id"]]
        out.append(
            '{}Add({}, "{}", 0)'.format(
                indent, entry["id"], escape_lua(translated)
            )
        )
    return newline.join(out) + newline


def write_locale(path: Path, content: str):
    with path.open("w", encoding="utf-8", newline="") as handle:
        handle.write(content)


# --------------------------------------------------------------------------
# ESO client terminology
# --------------------------------------------------------------------------

def load_client_strings(path: Path) -> dict[str, str]:
    strings = {}
    if not path.exists():
        return strings
    with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
        for line in handle:
            match = CLIENT_STRING.search(line)
            if match:
                strings[match.group("id")] = unescape_lua(match.group("text"))
    return strings


def clean_official_text(value: str) -> str:
    # ESO grammar tags such as ^m, ^f, ^n, ^p are not display text.
    return re.sub(r"\^[A-Za-z]", "", value).strip()


def build_official_map(client_dir: Path, targets):
    result = {}
    if not client_dir.exists():
        print("Client language files not found at {}; skipping official terms.".format(client_dir))
        return result

    english = load_client_strings(client_dir / "en_client.lua")
    localized = {
        lang: load_client_strings(client_dir / "{}_client.lua".format(lang))
        for lang in targets
    }

    reverse = {}
    for string_id, text in english.items():
        reverse.setdefault(text, string_id)

    for text, string_id in reverse.items():
        if text in OVERRIDES:
            official = {
                lang: OVERRIDES[text][lang]
                for lang in targets
                if lang in OVERRIDES[text]
            }
            if len(official) == len(targets):
                result[text] = official
            continue

        official = {}
        valid = True
        for lang in targets:
            value = localized[lang].get(string_id)
            if not value or "|c" in value or "|r" in value:
                valid = False
                break
            value = clean_official_text(value)
            if not value:
                valid = False
                break
            official[lang] = value
        if valid:
            result[text] = official
    return result


# --------------------------------------------------------------------------
# Translation backends
# --------------------------------------------------------------------------

class GoogleBackend:
    name = "google"
    ENDPOINT = "https://translate.googleapis.com/translate_a/single"

    def __init__(self, delay):
        self.delay = delay

    def translate(self, text: str, target: str, retries: int = 4) -> str:
        params = urllib.parse.urlencode(
            {"client": "gtx", "sl": "en", "tl": backend_code(target), "dt": "t", "q": text}
        )
        request = urllib.request.Request(
            "{}?{}".format(self.ENDPOINT, params),
            headers={"User-Agent": "Mozilla/5.0 (KelaPadUI translator)"},
        )
        wait = 1.0
        for attempt in range(retries + 1):
            try:
                with urllib.request.urlopen(request, timeout=30) as response:
                    data = json.load(response)
                translated = "".join(
                    segment[0]
                    for segment in data[0]
                    if segment and segment[0]
                )
                if not translated:
                    raise ValueError("empty translation")
                time.sleep(self.delay)
                return translated
            except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError,
                    json.JSONDecodeError, ValueError, IndexError) as exc:
                if attempt >= retries:
                    raise RuntimeError(
                        "Google translation failed for {!r}: {}".format(text[:60], exc)
                    )
                time.sleep(wait)
                wait *= 2
        raise RuntimeError("unreachable")


class ArgosBackend:
    name = "argos"

    def __init__(self, targets):
        try:
            import argostranslate.package  # noqa: F401
            import argostranslate.translate  # noqa: F401
        except ImportError:
            print("argostranslate is not installed; installing it...")
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", "argostranslate"]
            )
            import argostranslate.package  # noqa: F401
            import argostranslate.translate  # noqa: F401

        import argostranslate.package
        import argostranslate.translate

        self.package = argostranslate.package
        self.translate_module = argostranslate.translate
        self.package.update_package_index()
        available = self.package.get_available_packages()
        installed = {
            (package.from_code, package.to_code)
            for package in self.package.get_installed_packages()
        }
        for target in (backend_code(code) for code in targets):
            if ("en", target) in installed:
                continue
            package = next(
                (
                    candidate
                    for candidate in available
                    if candidate.from_code == "en" and candidate.to_code == target
                ),
                None,
            )
            if package is None:
                raise SystemExit(
                    "No argostranslate en->{} model is available.".format(target)
                )
            print("Downloading argostranslate en->{} model...".format(target))
            self.package.install_from_path(package.download())

    def translate(self, text: str, target: str, retries: int = 0) -> str:
        translation = self.translate_module.get_translation_from_codes("en", backend_code(target).split("-")[0])
        return translation.translate(text)


# --------------------------------------------------------------------------
# Translation orchestration
# --------------------------------------------------------------------------

class Cache:
    def __init__(self, path: Path):
        self.path = path
        try:
            with path.open("r", encoding="utf-8") as handle:
                self.data = json.load(handle)
        except (OSError, json.JSONDecodeError):
            self.data = {}
        self.dirty = False

    def get(self, backend, target, text):
        return self.data.get("{}|{}|{}".format(backend, target, text))

    def put(self, backend, target, text, translated):
        self.data["{}|{}|{}".format(backend, target, text)] = translated
        self.dirty = True
        self.save()

    def save(self):
        if not self.dirty:
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        temporary = self.path.with_suffix(".tmp")
        with temporary.open("w", encoding="utf-8") as handle:
            json.dump(self.data, handle, ensure_ascii=False, indent=1)
        temporary.replace(self.path)
        self.dirty = False


def protect_brands(text: str):
    placeholders = {}
    protected = text
    for index, brand in enumerate(BRAND_TOKENS):
        if brand in protected:
            marker = "[[KPUI_BRAND_{}]]".format(index)
            placeholders[marker] = brand
            protected = protected.replace(brand, marker)
    return protected, placeholders


def protect_plain_tokens(text: str):
    placeholders = {}
    protected = text
    index = 0
    while True:
        match = PLAIN_TOKEN.search(protected)
        if not match:
            break
        marker = "[[KPUI_T{}]]".format(index)
        placeholders[marker] = match.group(0)
        protected = protected[: match.start()] + marker + protected[match.end():]
        index += 1
    return protected, placeholders


def restore_placeholders(text: str, placeholders) -> str:
    for marker, value in placeholders.items():
        text = text.replace(marker, value)
    return text


def translate_text(backend, cache, target, text, force):
    if not re.search(r"[A-Za-z]", text):
        return text, "unchanged"

    protected, placeholders = protect_brands(text)
    protected, token_placeholders = protect_plain_tokens(protected)
    placeholders.update(token_placeholders)
    cached = None if force else cache.get(backend.name, target, protected)
    if cached is not None:
        return restore_placeholders(cached, placeholders), "cache"

    last_error = None
    for attempt in range(2):
        try:
            translated_raw = backend.translate(protected, target)
        except RuntimeError as exc:
            last_error = exc
            continue

        missing = [marker for marker in placeholders if marker not in translated_raw]
        if missing:
            last_error = RuntimeError(
                "placeholder lost: {}".format(", ".join(missing))
            )
            continue

        translated = restore_placeholders(translated_raw, placeholders)
        if token_signature(translated) != token_signature(text):
            last_error = RuntimeError("placeholder structure changed")
            continue

        cache.put(backend.name, target, protected, translated_raw)
        return translated, "translated"

    print("  ! falling back to English for {!r}: {}".format(text[:50], last_error))
    return text, "fallback"


def build_translations(entries, targets, official, backend, cache, force):
    unique = []
    seen = set()
    for entry in entries:
        if entry["text"] not in seen:
            seen.add(entry["text"])
            unique.append(entry["text"])

    results = {target: {} for target in targets}
    stats = {target: {"official": 0, "cache": 0, "translated": 0, "fallback": 0}
             for target in targets}

    for index, text in enumerate(unique, start=1):
        if text in official:
            for target in targets:
                results[target][text] = official[text][target]
                stats[target]["official"] += 1
            continue

        override = OVERRIDES.get(text, {})
        for target in targets:
            # Hand-pinned text wins for any string, per language; the official
            # map above only covers strings that also exist in the ESO client.
            if target in override:
                results[target][text] = override[target]
                stats[target]["official"] += 1
                continue
            translated, kind = translate_text(backend, cache, target, text, force)
            results[target][text] = translated
            if kind == "cache":
                stats[target]["cache"] += 1
            elif kind == "fallback":
                stats[target]["fallback"] += 1
            elif kind == "translated":
                stats[target]["translated"] += 1
        if index % 25 == 0:
            print("  {}/{}".format(index, len(unique)))
    return results, stats


# --------------------------------------------------------------------------
# Validation
# --------------------------------------------------------------------------

def validate_locale(path: Path, source_entries, target):
    lines, newline = read_lines(path)
    parsed = []
    for line_number, line in enumerate(lines, start=1):
        if "Add(KELA_" not in line:
            continue
        match = SAFE_ADD_LINE.match(line)
        if not match:
            return ["{}:{}: unparsable localized line".format(path.name, line_number)]
        parsed.append((match.group("id"), unescape_lua(match.group("text"))))

    errors = []
    source_ids = [entry["id"] for entry in source_entries]
    if [entry_id for entry_id, _ in parsed] != source_ids:
        errors.append("{}: ID list/order differs from en.lua".format(path.name))

    source_by_id = {entry["id"]: entry["text"] for entry in source_entries}
    for entry_id, translated in parsed:
        source = source_by_id.get(entry_id)
        if source is None:
            errors.append("{}: unknown ID {}".format(path.name, entry_id))
            continue
        if token_signature(translated) != token_signature(source):
            errors.append(
                "{}: placeholder mismatch in {}".format(path.name, entry_id)
            )
        for brand in BRAND_TOKENS:
            if translated.count(brand) != source.count(brand):
                errors.append(
                    "{}: brand token changed in {}".format(path.name, entry_id)
                )
        for code in ("|c", "|r"):
            if translated.count(code) != source.count(code):
                errors.append(
                    "{}: color code changed in {}".format(path.name, entry_id)
                )
        if "[[KPUI_BRAND_" in translated or "[[KPUI_T" in translated:
            errors.append("{}: leftover placeholder in {}".format(path.name, entry_id))
    if newline != "\r\n":
        errors.append("{}: expected CRLF line endings".format(path.name))
    return errors


def parse_locale_entries(path: Path):
    lines, _ = read_lines(path)
    entries = []
    for line in lines:
        match = SAFE_ADD_LINE.match(line)
        if match:
            entries.append((match.group("id"), unescape_lua(match.group("text"))))
    return entries


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("language", nargs="*", help="target language code(s)")
    parser.add_argument("--all", action="store_true", help="generate de, fr and ru")
    parser.add_argument("--offline", action="store_true",
                        help="use argostranslate instead of the Google endpoint")
    parser.add_argument("--force", action="store_true", help="ignore the cache")
    parser.add_argument("--dry-run", action="store_true", help="parse and report only")
    parser.add_argument("--check", action="store_true",
                        help="validate existing locale files and exit")
    parser.add_argument("--client-lang-dir", type=Path,
                        default=DEFAULT_CLIENT_LANG_DIR,
                        help="path to the ESO esoui/lang folder")
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE,
                        help="translation cache path")
    args = parser.parse_args()

    targets = list(args.language)
    if args.all:
        targets.extend(CAMPAIGN)
    targets = list(dict.fromkeys(targets))
    if not targets:
        parser.error("pass at least one language, or --all")

    for target in targets:
        if target == "en":
            parser.error("refusing to overwrite the English source")
        if not re.fullmatch(r"[a-z]{2}", target):
            parser.error("unsupported language code: {}".format(target))

    source_lines, newline, entries = parse_source(EN_PATH)
    print("Source: {} entries, {} unique strings, {} line ending".format(
        len(entries), len({entry["text"] for entry in entries}),
        "CRLF" if newline == "\r\n" else "LF",
    ))

    if args.check:
        errors = []
        for target in targets:
            path = LANG_DIR / "{}.lua".format(target)
            if not path.exists():
                errors.append("{}: missing".format(path.name))
            else:
                errors.extend(validate_locale(path, entries, target))
        for error in errors:
            print("ERROR:", error)
        print("CHECK FAILED" if errors else "CHECK PASSED")
        return 1 if errors else 0

    official = build_official_map(args.client_lang_dir, targets)
    official = {
        text: values
        for text, values in official.items()
        if all(
            token_signature(value) == token_signature(text)
            for value in values.values()
        )
    }
    official_hits = sum(
        1 for entry in entries if entry["text"] in official
    )
    print("Official ESO matches: {} unique strings".format(
        len({entry["text"] for entry in entries if entry["text"] in official})
    ))

    if args.dry_run:
        print("Dry run: would write {} file(s): {}".format(
            len(targets), ", ".join(targets)
        ))
        print("Official entries:", official_hits)
        return 0

    cache = Cache(args.cache)
    if args.offline:
        try:
            backend = ArgosBackend(targets)
        except subprocess.CalledProcessError as exc:
            print("Could not install/import argostranslate: {}".format(exc))
            print("Use the default Google backend, or install argostranslate on "
                  "a Python version with CTranslate2 wheels (3.9-3.13).")
            return 1
    else:
        backend = GoogleBackend(delay=0.1)

    translations, stats = build_translations(
        entries, targets, official, backend, cache, args.force
    )

    for target in targets:
        path = LANG_DIR / "{}.lua".format(target)
        content = render_locale(
            source_lines, newline, entries,
            {entry["id"]: translations[target][entry["text"]] for entry in entries},
            target,
        )
        write_locale(path, content)
        errors = validate_locale(path, entries, target)
        for error in errors:
            print("ERROR:", error)
        print("Wrote {} ({})".format(
            path.relative_to(ROOT),
            ", ".join("{} {}".format(key, value)
                      for key, value in stats[target].items()),
        ))
        if errors:
            return 1

    print("Done. Run python _tools/audit_addon.py to validate the add-on.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
