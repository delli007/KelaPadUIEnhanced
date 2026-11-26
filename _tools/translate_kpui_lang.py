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
    "Healing": {"de": "Heilung", "fr": "Soins", "ru": "Лечение", "jp": "回復力", "es": "Curación", "zh": "治疗"},
    "Recovery": {"jp": "再生"},
    "Normal": {"jp": "普通", "zh": "一般"},
    "Researched: <<1>>": {"jp": "研究済み: <<1>>", "zh": "已研究：<<1>>"},
    # Deal ratings agree with "oferta" in Spanish; plain adjectives in Chinese.
    "Good": {"es": "Buena", "zh": "好"},
    "Bad": {"es": "Mala", "zh": "差"},
    "Terrible": {"zh": "很差"},
    "Excellent": {"zh": "极好"},
    "Complete": {"zh": "已完成"},
    "<<1>> active - <<2>>": {"zh": "<<1>> 项进行中 - <<2>>"},
    # Character Knowledge: game terms from <code>_client.lua; machine
    # translation left these in English or picked the wrong sense.
    "Server": {"fr": "Serveur", "ru": "Сервер", "jp": "サーバー", "es": "Servidor", "zh": "服务器"},
    "Known": {"de": "Bekannt", "jp": "習得済み"},
    "Quality": {"jp": "品質"},
    "Characters": {"zh": "角色"},
    "Adds Character Knowledge to the KelaPadUI² menu when LibCharacterKnowledge is installed: which recipes, furnishing plans, motifs, and scribing items each character knows, with filters and the item tooltip.": {"de": "Fügt dem KelaPadUI²-Menü Character Knowledge hinzu, wenn LibCharacterKnowledge installiert ist: welche Rezepte, Einrichtungspläne, Stile und Schriftlehre-Gegenstände jeder Charakter kennt, mit Filtern und dem Gegenstands-Tooltip.", "fr": "Ajoute Character Knowledge au menu KelaPadUI² quand LibCharacterKnowledge est installé : les recettes, plans d'ameublement, styles et objets d'écriture que connaît chaque personnage, avec des filtres et l'infobulle de l'objet.", "ru": "Добавляет Character Knowledge в меню KelaPadUI², если установлена LibCharacterKnowledge: какие рецепты, инструкции для предметов обстановки, ремесленные мотивы и предметы чарописи знает каждый персонаж, с фильтрами и подсказкой предмета.", "jp": "LibCharacterKnowledgeがインストールされている場合、KelaPadUI²メニューにCharacter Knowledgeを追加します。各キャラクターが習得しているレシピ、家具の設計図、モチーフ、書記アイテムを、フィルターとアイテムのツールチップ付きで表示します。", "es": "Añade Character Knowledge al menú KelaPadUI² cuando LibCharacterKnowledge está instalado: qué recetas, planos de mobiliario, motivos y objetos de escribanía conoce cada personaje, con filtros y la descripción del objeto.", "zh": "安装LibCharacterKnowledge后，在KelaPadUI²菜单中添加Character Knowledge：显示每个角色已学会的配方、装饰品图纸、样式书和篆刻物品，并提供筛选和物品提示。"},
    # Browser screens: "Shown" is a filter state, not "as shown".
    # Price tooltip: "Average" is the mean price.
    "Average": {"de": "Durchschnitt", "fr": "Moyenne", "ru": "Среднее", "jp": "平均", "es": "Promedio", "zh": "平均"},
    "Listings": {"de": "Angebote", "fr": "Mises en vente", "ru": "Предложения", "jp": "出品", "es": "Anuncios", "zh": "挂单"},
    # Fight Stats group, champion and damage profile strings.
    "Single target": {"ru": "Одна цель", "jp": "単体", "zh": "单体"},
    "Area damage": {"ru": "Урон по области", "es": "Daño en área", "fr": "Dégâts de zone", "zh": "范围伤害"},
    "Damage profile": {"ru": "Профиль урона", "jp": "ダメージ傾向", "es": "Perfil de daño", "zh": "伤害概况"},
    "Delivery and targets": {"de": "Art und Ziele", "fr": "Type et cibles", "ru": "Тип и цели", "jp": "種類と対象", "es": "Tipo y objetivos", "zh": "类型与目标"},
    "Single target, direct": {"fr": "Cible unique, directs", "ru": "Одна цель, прямой", "jp": "単体・直接", "zh": "单体，直接"},
    "Single target, over time": {"de": "Einzelziel, über Zeit", "fr": "Cible unique, sur la durée", "ru": "Одна цель, периодический", "jp": "単体・継続", "es": "Objetivo único, con el tiempo", "zh": "单体，持续"},
    "Area, direct": {"de": "Fläche, direkt", "fr": "Zone, directs", "ru": "Область, прямой", "jp": "範囲・直接", "es": "Área, directo", "zh": "范围，直接"},
    "Area, over time": {"de": "Fläche, über Zeit", "fr": "Zone, sur la durée", "ru": "Область, периодический", "jp": "範囲・継続", "es": "Área, con el tiempo", "zh": "范围，持续"},
    "Group totals": {"ru": "Итого по группе", "zh": "队伍总计"},
    "You were not in a group for this fight.": {"ru": "В этом бою вы были не в группе.", "jp": "この戦闘ではグループに参加していませんでした。", "zh": "这场战斗中你不在队伍里。"},
    "Slotted stars": {"de": "Ausgerüstete Sterne", "fr": "Étoiles équipées", "ru": "Выбранные звёзды", "jp": "セット中のスター", "es": "Estrellas equipadas", "zh": "已装备的星星"},
    "The game does not share other players' gear or skills, so only their role, class, level, and results are shown. Area damage is estimated from each skill's radius or cone.": {"ru": "Игра не показывает снаряжение и навыки других игроков, поэтому видны только их роль, класс, уровень и результаты. Урон по области оценивается по радиусу или конусу каждого навыка.", "jp": "ゲームは他のプレイヤーの装備やスキルを公開しないため、役割、クラス、レベル、結果のみ表示されます。範囲ダメージは各スキルの半径または円錐から推定されます。"},
    "These are the champion stars you had slotted, with what the game says each gave at your points. Compare them with your damage profile to judge which fit. Estimating the gain from swapping a star needs per-star data that is not available yet.": {"de": "Das sind die ausgerüsteten Championsterne mit dem, was das Spiel für deine Punkte angibt. Vergleiche sie mit deinem Schadensprofil, um zu beurteilen, welche passen. Um den Gewinn durch den Tausch eines Sterns zu schätzen, fehlen noch Daten pro Stern.", "fr": "Voici les étoiles de champion que vous aviez équipées, avec le bonus indiqué par le jeu pour vos points. Comparez-les à votre profil de dégâts pour juger lesquelles conviennent. Estimer le gain d'un échange d'étoile demande des données par étoile qui ne sont pas encore disponibles.", "ru": "Это экипированные звёзды чемпиона и бонус, который игра показывает для ваших очков. Сравните их с профилем урона, чтобы понять, какие подходят. Для оценки выгоды от замены звезды нужны данные по каждой звезде, которых пока нет.", "jp": "装備していたチャンピオンスターと、ゲームが示すあなたのポイントでの効果です。ダメージ傾向と見比べて、どれが合っているか判断してください。スターを入れ替えた場合の効果の推定には、まだ利用できないスターごとのデータが必要です。", "es": "Estas son las estrellas de campeón que tenías equipadas, con lo que indica el juego para tus puntos. Compáralas con tu perfil de daño para juzgar cuáles encajan. Estimar la ganancia de cambiar una estrella requiere datos por estrella que aún no están disponibles.", "zh": "这些是你装备的冠军星星，以及游戏显示的在你当前点数下的效果。请对照你的伤害概况，判断哪些合适。要估算更换星星带来的收益，还需要目前尚未提供的每颗星星的数据。"},
    "Ultimate Recovery": {"de": "Regeneration der ultimativen Fähigkeit", "fr": "Récupération d'ultime", "ru": "Восст. суперспособности", "jp": "アルティメット再生", "es": "Recuperación de máxima", "zh": "终极恢复"},
    "CP": {"de": "CP", "fr": "CP", "ru": "CP", "jp": "CP", "es": "CP", "zh": "CP"},
    # Fight Stats detail pages: terms the machine translation got wrong.
    "Buffs": {"de": "Buffs", "fr": "Buffs", "ru": "Баффы", "es": "Mejoras"},
    "Damage by skill": {"de": "Schaden pro Fertigkeit", "fr": "Dégâts par compétence", "ru": "Урон по навыкам", "jp": "スキル別ダメージ", "es": "Daño por habilidad", "zh": "按技能伤害"},
    "Damage mix": {"de": "Schadensverteilung", "fr": "Répartition des dégâts", "ru": "Структура урона", "jp": "ダメージ内訳", "es": "Distribución del daño", "zh": "伤害构成"},
    "Direct damage": {"fr": "Dégâts directs", "ru": "Прямой урон", "zh": "直接伤害"},
    "Damage over time": {"de": "Schaden über Zeit", "fr": "Dégâts sur la durée", "ru": "Периодический урон", "jp": "継続ダメージ", "zh": "持续伤害"},
    "Damage types": {"fr": "Types de dégâts", "ru": "Типы урона", "es": "Tipos de daño", "zh": "伤害类型"},
    "<<1[$d cast/$d casts]>>": {"de": "<<1[$d Einsatz/$d Einsätze]>>", "fr": "<<1[$d lancer/$d lancers]>>", "ru": "<<1[$d применение/$d применений]>>", "jp": "<<1[$d 回使用/$d 回使用]>>", "es": "<<1[$d lanzamiento/$d lanzamientos]>>", "zh": "<<1[$d 次施放/$d 次施放]>>"},
    "<<1[$d hit/$d hits]>>": {"fr": "<<1[$d coup/$d coups]>>", "ru": "<<1[$d попадание/$d попаданий]>>", "es": "<<1[$d impacto/$d impactos]>>", "zh": "<<1[$d 次命中/$d 次命中]>>"},
    "<<1>>% crit": {"de": "<<1>>% Krit.", "ru": "<<1>>% крит."},
    "Your buffs": {"ru": "Ваши баффы", "es": "Tus mejoras", "zh": "你的增益"},
    "Your debuffs": {"es": "Tus debuffs"},
    "Enemy debuffs": {"de": "Debuffs auf Gegnern", "es": "Debuffs enemigos", "zh": "敌人减益"},
    "Enemy buffs": {"de": "Buffs auf Gegnern", "ru": "Баффы врагов"},
    "Offense": {"fr": "Offensive", "ru": "Атака", "es": "Ofensiva", "zh": "输出"},
    "Resources": {"de": "Ressourcen"},
    "max": {"de": "max.", "fr": "max.", "ru": "макс.", "es": "máx.", "zh": "最大"},
    "Spell critical": {"de": "Zauberkritisch", "fr": "Critique des sorts", "ru": "Крит. заклинаний", "es": "Crítico de hechizos", "zh": "法术暴击"},
    "Weapon critical": {"fr": "Critique des armes", "ru": "Крит. оружия", "es": "Crítico de arma", "zh": "武器暴击"},
    "Spell power": {"fr": "Puissance des sorts", "ru": "Сила заклинаний", "es": "Poder de hechizo"},
    "Weapon power": {"ru": "Сила оружия", "es": "Poder de arma"},
    "Critical damage": {"fr": "Dégâts critiques", "zh": "暴击伤害"},
    "Max magicka": {"de": "Max. Magicka", "fr": "Magie max.", "ru": "Макс. магия", "es": "Magia máx.", "zh": "最大魔力"},
    "Max stamina": {"es": "Aguante máx."},
    # Fight Stats sheet: terms the machine translation got wrong.
    "Overview": {"ru": "Обзор"},
    "Loadout": {"de": "Ausstattung", "fr": "Configuration", "ru": "Экипировка", "jp": "ロードアウト", "es": "Configuración", "zh": "配置"},
    "Your share": {"es": "Tu parte", "zh": "你的占比"},
    "DPS taken": {"de": "Erlittener DPS", "fr": "DPS subi", "ru": "Полученный DPS", "jp": "被ダメージDPS", "es": "DPS recibido", "zh": "承受 DPS"},
    "Role": {"es": "Rol"},
    "Armor": {"jp": "防具"},
    "Overland": {"de": "Oberwelt", "fr": "Monde ouvert", "ru": "Открытый мир", "jp": "オープンワールド", "es": "Mundo abierto", "zh": "开放世界"},
    "Battleground": {"ru": "Поле боя", "jp": "戦場"},
    "No loadout was recorded for this fight.": {"de": "Für diesen Kampf wurde keine Ausstattung aufgezeichnet.", "fr": "Aucune configuration n'a été enregistrée pour ce combat.", "ru": "Для этого боя экипировка не записана.", "es": "No se registró ninguna configuración para este combate.", "zh": "这场战斗没有记录配置信息。"},
    # Fight Stats: the machine translation read "kept", "gear", "bar", and the DPS terms wrongly.
    "Fights": {"de": "Kämpfe", "fr": "Combats", "ru": "Бои", "jp": "戦闘", "es": "Combates", "zh": "战斗"},
    "Loadouts": {"jp": "ビルド"},
    "Length": {"de": "Dauer", "fr": "Durée", "ru": "Длительность", "jp": "時間", "es": "Duración", "zh": "时长"},
    "DPS": {"de": "DPS", "fr": "DPS", "ru": "DPS", "jp": "DPS", "es": "DPS", "zh": "DPS"},
    "HPS": {"fr": "HPS", "ru": "HPS", "zh": "HPS"},
    "Target": {"ru": "Цель", "es": "Objetivo"},
    "Zone": {"ru": "Зона"},
    "PvE": {"ru": "PvE", "zh": "PvE"},
    "Entries": {"zh": "条目"},
    "Gear": {"de": "Ausrüstung", "fr": "Équipement", "ru": "Снаряжение", "jp": "装備", "es": "Equipo", "zh": "装备"},
    "Group DPS": {"ru": "DPS группы", "zh": "团队 DPS"},
    "Bar <<1>>": {"de": "Leiste <<1>>", "ru": "Панель <<1>>", "zh": "技能栏 <<1>>"},
    "Health / Magicka / Stamina": {"jp": "体力 / マジカ / スタミナ"},
    "<<1[$d fight/$d fights]>>": {"ru": "<<1[$d бой/$d боёв]>>", "zh": "<<1[$d 场战斗/$d 场战斗]>>"},
    "Fights kept": {"de": "Gespeicherte Kämpfe", "fr": "Combats conservés", "ru": "Сохраняемые бои", "jp": "保存する戦闘数", "es": "Combates guardados", "zh": "保留的战斗数"},
    "Record PvE fights": {"de": "PvE-Kämpfe aufzeichnen", "fr": "Enregistrer les combats PvE", "ru": "Записывать PvE-бои", "jp": "PvEの戦闘を記録", "es": "Registrar combates PvE", "zh": "记录 PvE 战斗"},
    "Record battlegrounds": {"de": "Schlachtfelder aufzeichnen", "fr": "Enregistrer les champs de bataille", "ru": "Записывать поля боя", "jp": "戦場を記録", "es": "Registrar campos de batalla", "zh": "记录战场"},
    # "Cleared" means completed here, not wiped.
    "Link Cleared": {"de": "Erledigte verlinken", "fr": "Lier les terminés", "ru": "Ссылки на выполненные", "jp": "達成済みをリンク", "es": "Enlazar completados", "zh": "链接已完成"},
    "Link Uncleared": {"de": "Offene verlinken", "fr": "Lier les restants", "ru": "Ссылки на невыполненные", "jp": "未達成をリンク", "es": "Enlazar pendientes", "zh": "链接未完成"},
    "Shown": {"de": "Angezeigt", "fr": "Affichés", "ru": "Показаны", "jp": "表示", "es": "Visibles", "zh": "显示"},
    "Hide Arc 1 (Infinite Archive)": {"de": "Arc 1 ausblenden (Infinite Archive)", "fr": "Masquer l'Arc 1 (Archive Infinie)", "ru": "Скрыть Арку 1 (Бесконечный архив)", "jp": "アーク1を非表示 (無限アーカイブ)", "es": "Ocultar el Arco 1 (Archivo Infinito)", "zh": "隐藏弧线 1（无限存档）"},
    # Fight Stats 3.0.0 review. The machine translation read "bar" as a pub,
    # "cap" as a lid, "cast" as a film cast, "weave" as knitting and "boss" as
    # an employer. Game terms come from <code>_client.lua: Ultimate
    # (SI_COMBATMECHANICFLAGS8), Healing Done (SI_DERIVEDSTATS12, "Soins" in
    # French), Champion Points, Mundus Stone and Class Mastery. Weaving is kept
    # as the players' word where the language has no game term for it.
    "Fight Stats": {"de": "Kampfstatistiken", "fr": "Statistiques de combat", "ru": "Статистика боя", "jp": "戦闘統計", "es": "Estadísticas de combate", "zh": "战斗统计"},
    "Adds Fight Stats to the KelaPadUI² menu: your recent fights with damage, DPS, and HPS, and the gear sets, skills, scribed scripts, and champion points you fought with. It reads fight data from LibCombat, which Combat Metrics installs. L1 and R1 switch pages.": {
        "de": "Fügt dem KelaPadUI²-Menü Kampfstatistiken hinzu: deine letzten Kämpfe mit Schaden, DPS und HPS sowie die Sets, Fertigkeiten, Skripturen und Championpunkte, mit denen du gekämpft hast. Die Kampfdaten stammen aus LibCombat, das mit Combat Metrics installiert wird. L1 und R1 wechseln die Seiten.",
        "fr": "Ajoute les statistiques de combat au menu KelaPadUI² : vos combats récents avec dégâts, DPS et HPS, ainsi que les ensembles, compétences, scripts d'écriture et points de Champion avec lesquels vous avez combattu. Les données viennent de LibCombat, installé avec Combat Metrics. L1 et R1 changent de page.",
        "ru": "Добавляет статистику боя в меню KelaPadUI²: ваши недавние бои с уроном, DPS и HPS, а также комплекты, навыки, записи чарописи и очки героя, с которыми вы сражались. Данные боя берутся из LibCombat, который устанавливается вместе с Combat Metrics. L1 и R1 переключают страницы.",
        "jp": "KelaPadUI²メニューに戦闘統計を追加します。最近の戦闘のダメージ、DPS、HPSと、そのときのセット、スキル、書記のスクリプト、チャンピオンポイントを表示します。戦闘データはCombat Metricsと一緒にインストールされるLibCombatから読み取ります。L1とR1でページを切り替えます。",
        "es": "Añade Estadísticas de combate al menú KelaPadUI²: tus combates recientes con daño, DPS y HPS, y los conjuntos, habilidades, escrituras y puntos de campeón con los que luchaste. Los datos vienen de LibCombat, que se instala con Combat Metrics. L1 y R1 cambian de página.",
        "zh": "在KelaPadUI²菜单中添加战斗统计：你最近战斗的伤害、DPS和HPS，以及战斗时使用的套装、技能、篆刻脚本和勇士点数。战斗数据来自随Combat Metrics安装的LibCombat。L1和R1切换页面。",
    },
    "How many fights Fight Stats remembers. When the list is full, other fights make room before boss fights and battleground matches do. Combat Metrics keeps its own fight history with its own setting. Estimated memory at this setting: about <<1>>. Long fights and large groups use more.": {
        "de": "Wie viele Kämpfe die Kampfstatistiken speichern. Ist die Liste voll, machen andere Kämpfe zuerst Platz, vor Bosskämpfen und Schlachtfeld-Matches. Combat Metrics führt einen eigenen Kampfverlauf mit eigener Einstellung. Geschätzter Speicher bei diesem Wert: etwa <<1>>. Lange Kämpfe und große Gruppen brauchen mehr.",
        "fr": "Nombre de combats conservés par les statistiques de combat. Quand la liste est pleine, les autres combats laissent leur place avant les combats de boss et les matchs de champ de bataille. Combat Metrics garde son propre historique avec son propre réglage. Mémoire estimée pour cette valeur : environ <<1>>. Les longs combats et les grands groupes en utilisent davantage.",
        "ru": "Сколько боёв хранит статистика боя. Когда список заполнен, сначала удаляются обычные бои, а бои с боссами и матчи на полях сражений — в последнюю очередь. Combat Metrics ведёт собственную историю боёв со своей настройкой. Примерный объём памяти при этом значении: около <<1>>. Долгие бои и большие группы занимают больше.",
        "jp": "戦闘統計が保存する戦闘の数です。リストがいっぱいになると、ボス戦やバトルグラウンドの試合より先に、それ以外の戦闘が削除されます。Combat Metricsは独自の設定で独自の戦闘履歴を保持します。この設定での推定メモリ: 約<<1>>。長い戦闘や大人数のグループではより多く使用します。",
        "es": "Cuántos combates guarda Estadísticas de combate. Cuando la lista está llena, los demás combates dejan sitio antes que los combates contra jefes y las partidas de campo de batalla. Combat Metrics mantiene su propio historial con su propio ajuste. Memoria estimada con este valor: unos <<1>>. Los combates largos y los grupos grandes usan más.",
        "zh": "战斗统计保存的战斗数量。列表已满时，会先删除其他战斗，Boss战和战场比赛最后才会被删除。Combat Metrics使用自己的设置保留自己的战斗历史。此设置下的估计内存：约<<1>>。长时间战斗和大型队伍会占用更多。",
    },
    "Records each battleground match as one entry, added up when the match ends. Cyrodiil, Imperial City, Vengeance, and Jerall Pass are never recorded, to keep the game running smoothly.": {
        "de": "Zeichnet jedes Schlachtfeld-Match als einen Eintrag auf, der bei Matchende zusammengezählt wird. Cyrodiil, die Kaiserstadt, Vengeance und der Jerallpass werden nie aufgezeichnet, damit das Spiel flüssig läuft.",
        "fr": "Enregistre chaque match de champ de bataille comme une seule entrée, additionnée à la fin du match. Cyrodiil, la Cité impériale, Vengeance et le col de Jerall ne sont jamais enregistrés, pour que le jeu reste fluide.",
        "ru": "Записывает каждый матч на поле боя одной записью, которая суммируется по окончании матча. Сиродил, Имперский город, Vengeance и Джераллский перевал никогда не записываются, чтобы игра работала плавно.",
        "jp": "バトルグラウンドの各試合を1件として記録し、試合終了時に合計します。シロディール、帝都、Vengeance、ジェラール山道はゲームを快適に保つため記録しません。",
        "es": "Registra cada partida de campo de batalla como una entrada, sumada al terminar la partida. Cyrodiil, la Ciudad Imperial, Vengeance y el paso de Jerall nunca se registran, para que el juego siga fluido.",
        "zh": "将每场战场比赛记录为一条，比赛结束时汇总。为保持游戏流畅，西罗帝尔、帝都、Vengeance和杰拉尔山口永远不会被记录。",
    },
    "Weave time": {"de": "Weaving-Zeit", "fr": "Temps de weaving", "ru": "Пауза между навыками", "jp": "ウィービング時間", "es": "Tiempo de weaving", "zh": "技能间隔"},
    "Weave errors": {"de": "Weaving-Fehler", "fr": "Erreurs de weaving", "ru": "Ошибки чередования", "jp": "ウィービングミス", "es": "Errores de weaving", "zh": "衔接错误"},
    "Damage over the cap": {"de": "Schaden über dem Limit", "fr": "Dégâts au-delà du plafond", "ru": "Урон сверх предела", "jp": "上限超過のダメージ", "es": "Daño por encima del límite", "zh": "超出上限的伤害"},
    "Highest": {"de": "Höchstwert", "fr": "Maximum", "ru": "Максимум", "jp": "最高", "es": "Máximo", "zh": "最高"},
    "Mundus stone": {"de": "Mundusstein", "fr": "Pierre de Mundus", "ru": "Камень Мундуса", "jp": "ムンダス・ストーン", "es": "Piedra de Mundus", "zh": "梦达思之石"},
    "Food and drink": {"de": "Essen und Trinken", "fr": "Nourriture et boisson", "ru": "Еда и напитки", "jp": "料理と飲み物", "es": "Comida y bebida", "zh": "食物和饮品"},
    "Mundus, food and potions": {"de": "Mundus, Essen und Tränke", "fr": "Mundus, nourriture et potions", "ru": "Мундус, еда и зелья", "jp": "ムンダス、料理、薬", "es": "Mundus, comida y pociones", "zh": "梦达思、食物和药水"},
    "Skills cast": {"de": "Gewirkte Fertigkeiten", "fr": "Compétences lancées", "ru": "Применено навыков", "jp": "スキル使用", "es": "Habilidades lanzadas", "zh": "技能施放"},
    "Rotation": {"de": "Rotation", "fr": "Rotation", "ru": "Ротация", "jp": "ローテーション", "es": "Rotación", "zh": "循环"},
    "Active time": {"de": "Aktive Zeit", "fr": "Temps actif", "ru": "Активное время", "jp": "アクティブ時間", "es": "Tiempo activo", "zh": "活跃时间"},
    "Best 10 seconds": {"de": "Beste 10 Sekunden", "fr": "Meilleures 10 secondes", "ru": "Лучшие 10 секунд", "jp": "ベスト10秒", "es": "Mejores 10 segundos", "zh": "最佳10秒"},
    "Best 10 seconds began": {"de": "Beste 10 Sekunden ab", "fr": "Début des meilleures 10 secondes", "ru": "Начало лучших 10 секунд", "jp": "ベスト10秒の開始", "es": "Inicio de los mejores 10 segundos", "zh": "最佳10秒开始于"},
    "Ultimates cast": {"de": "Ultimative Fähigkeiten gewirkt", "fr": "Ultimes lancés", "ru": "Применено суперспособностей", "jp": "アルティメット使用", "es": "Habilidades máximas lanzadas", "zh": "终极技能施放"},
    "Ultimate gained": {"de": "Ultimative erhalten", "fr": "Ultime gagné", "ru": "Получено очков суперспособности", "jp": "アルティメット獲得", "es": "Máxima obtenida", "zh": "获得终极点"},
    "Ultimate spent": {"de": "Ultimative verbraucht", "fr": "Ultime dépensé", "ru": "Потрачено очков суперспособности", "jp": "アルティメット消費", "es": "Máxima gastada", "zh": "消耗终极点"},
    "Top skills": {"de": "Top-Fertigkeiten", "fr": "Meilleures compétences", "ru": "Лучшие навыки", "jp": "上位スキル", "es": "Mejores habilidades", "zh": "主要技能"},
    "Top healing skills": {"de": "Top-Heilfertigkeiten", "fr": "Meilleures compétences de soin", "ru": "Лучшие навыки лечения", "jp": "上位回復スキル", "es": "Mejores habilidades de curación", "zh": "主要治疗技能"},
    "Boss damage": {"de": "Schaden an Anführern", "fr": "Dégâts aux boss", "ru": "Урон по боссам", "jp": "ボスへのダメージ", "es": "Daño a jefes", "zh": "对Boss伤害"},
    "Top target damage": {"de": "Schaden am Hauptziel", "fr": "Dégâts sur la cible principale", "ru": "Урон по главной цели", "jp": "主な対象へのダメージ", "es": "Daño al objetivo principal", "zh": "主要目标伤害"},
    "Deaths": {"de": "Tode", "fr": "Morts", "ru": "Смерти", "jp": "死亡", "es": "Muertes", "zh": "死亡"},
    "Bars": {"de": "Leisten", "fr": "Barres", "ru": "Панели", "jp": "バー", "es": "Barras", "zh": "技能栏"},
    "Time on bar": {"de": "Zeit auf der Leiste", "fr": "Temps sur la barre", "ru": "Время на панели", "jp": "バーの使用時間", "es": "Tiempo en la barra", "zh": "技能栏时间"},
    "Mitigation": {"de": "Schadensminderung", "fr": "Atténuation", "ru": "Снижение урона", "jp": "ダメージ軽減", "es": "Mitigación", "zh": "减伤"},
    "Hits taken": {"de": "Erlittene Treffer", "fr": "Coups reçus", "ru": "Полученные удары", "jp": "被弾数", "es": "Golpes recibidos", "zh": "受到的命中"},
    "Blocked": {"de": "Geblockt", "fr": "Bloqué", "ru": "Заблокировано", "jp": "防御", "es": "Bloqueado", "zh": "格挡"},
    "Absorbed by shields": {"de": "Von Schilden absorbiert", "fr": "Absorbé par les boucliers", "ru": "Поглощено щитами", "jp": "シールドで吸収", "es": "Absorbido por escudos", "zh": "被护盾吸收"},
    "Dodged": {"de": "Ausgewichen", "fr": "Esquivé", "ru": "Уклонения", "jp": "回避", "es": "Esquivado", "zh": "闪避"},
    "33,100 is a soft cap: more resistance still helps, but less each point.": {
        "de": "33.100 ist eine weiche Grenze: Mehr Resistenz hilft weiter, aber jeder Punkt weniger.",
        "fr": "33 100 est un plafond souple : plus de résistance aide encore, mais chaque point compte moins.",
        "ru": "33 100 — мягкий предел: больше сопротивляемости всё ещё помогает, но каждое очко даёт меньше.",
        "jp": "33,100はソフトキャップです。耐性を上げても効果はありますが、1ポイントあたりの効果は小さくなります。",
        "es": "33.100 es un límite blando: más resistencia sigue ayudando, pero cada punto aporta menos.",
        "zh": "33,100是软上限：更多抗性仍有帮助，但每点的效果更小。",
    },
    "Healing detail": {"de": "Heilungsdetails", "fr": "Détail des soins", "ru": "Подробности лечения", "jp": "回復の詳細", "es": "Detalle de curación", "zh": "治疗详情"},
    "Effective healing": {"de": "Effektive Heilung", "fr": "Soins effectifs", "ru": "Эффективное лечение", "jp": "有効回復", "es": "Curación efectiva", "zh": "有效治疗"},
    "Overhealing": {"de": "Überheilung", "fr": "Soins en excès", "ru": "Избыточное лечение", "jp": "オーバーヒール", "es": "Sobrecuración", "zh": "过量治疗"},
    "overhealed": {"de": "überheilt", "fr": "en excès", "ru": "избыточно", "jp": "オーバーヒール", "es": "sobrecuración", "zh": "过量治疗"},
    "Over time": {"de": "Über Zeit", "fr": "Sur la durée", "ru": "Периодическое", "jp": "継続回復", "es": "Prolongada", "zh": "持续治疗"},
    "Healing received": {"de": "Erhaltene Heilung", "fr": "Soins reçus", "ru": "Получаемое лечение", "jp": "被回復", "es": "Curación recibida", "zh": "受到的治疗"},
    "Healing by character": {"de": "Heilung pro Charakter", "fr": "Soins par personnage", "ru": "Лечение по персонажам", "jp": "キャラ別回復", "es": "Curación por personaje", "zh": "按角色治疗"},
    "Healing by skill": {"de": "Heilung pro Fertigkeit", "fr": "Soins par compétence", "ru": "Лечение по навыкам", "jp": "スキル別回復", "es": "Curación por habilidad", "zh": "按技能治疗"},
    "Damage by character": {"de": "Schaden pro Charakter", "fr": "Dégâts par personnage", "ru": "Урон по персонажам", "jp": "キャラ別ダメージ", "es": "Daño por personaje", "zh": "按角色伤害"},
    "Damage taken by ability": {"de": "Erlittener Schaden pro Fähigkeit", "fr": "Dégâts subis par compétence", "ru": "Полученный урон по способностям", "jp": "アビリティ別被ダメージ", "es": "Daño recibido por habilidad", "zh": "按技能受到的伤害"},
    "Damage taken": {"de": "Erlittener Schaden", "fr": "Dégâts subis", "ru": "Полученный урон", "jp": "被ダメージ", "es": "Daño recibido", "zh": "受到的伤害"},
    "Timeline": {"de": "Zeitverlauf", "fr": "Chronologie", "ru": "Ход боя", "jp": "タイムライン", "es": "Cronología", "zh": "时间轴"},
    "Boss health": {"de": "Leben des Anführers", "fr": "Santé du boss", "ru": "Здоровье босса", "jp": "ボスの体力", "es": "Salud del jefe", "zh": "Boss生命值"},
    "Deaths and revives": {"de": "Tode und Wiederbelebungen", "fr": "Morts et résurrections", "ru": "Смерти и воскрешения", "jp": "死亡と蘇生", "es": "Muertes y resurrecciones", "zh": "死亡与复活"},
    "<<1>> died": {"de": "<<1>> ist gestorben", "fr": "<<1>> est mort", "ru": "<<1>>: смерть", "jp": "<<1>>が死亡", "es": "<<1>> murió", "zh": "<<1>>死亡"},
    "<<1>> revived": {"de": "<<1>> wurde wiederbelebt", "fr": "<<1>> a été ressuscité", "ru": "<<1>>: воскрешение", "jp": "<<1>>が蘇生", "es": "<<1>> resucitó", "zh": "<<1>>复活"},
    "Killed by <<1>>": {"de": "Getötet durch <<1>>", "fr": "Tué par <<1>>", "ru": "Убийца: <<1>>", "jp": "<<1>>により死亡", "es": "Muerto por <<1>>", "zh": "被<<1>>击杀"},
    "Buff coverage": {"de": "Buff-Abdeckung", "fr": "Couverture des buffs", "ru": "Покрытие баффами", "jp": "バフの維持率", "es": "Cobertura de mejoras", "zh": "增益覆盖率"},
    "Under half: <<1>>": {"de": "Unter der Hälfte: <<1>>", "fr": "Moins de la moitié : <<1>>", "ru": "Меньше половины: <<1>>", "jp": "半分未満: <<1>>", "es": "Menos de la mitad: <<1>>", "zh": "不到一半：<<1>>"},
    "No essential buffs were recorded.": {"de": "Es wurden keine wichtigen Buffs aufgezeichnet.", "fr": "Aucun buff essentiel n'a été enregistré.", "ru": "Важные баффы не записаны.", "jp": "必須バフは記録されませんでした。", "es": "No se registraron mejoras esenciales.", "zh": "没有记录到必要增益。"},
    "Group damage taken": {"de": "Von der Gruppe erlittener Schaden", "fr": "Dégâts subis par le groupe", "ru": "Урон, полученный группой", "jp": "グループの被ダメージ", "es": "Daño recibido por el grupo", "zh": "队伍受到的伤害"},
    "Damage taken by member": {"de": "Erlittener Schaden pro Mitglied", "fr": "Dégâts subis par membre", "ru": "Полученный урон по участникам", "jp": "メンバー別被ダメージ", "es": "Daño recibido por miembro", "zh": "按成员受到的伤害"},
    "Are you sure?": {"de": "Bist du sicher?", "fr": "Êtes-vous sûr ?", "ru": "Вы уверены?", "jp": "よろしいですか？", "es": "¿Estás seguro?", "zh": "确定吗？"},
    "Delete": {"de": "Löschen", "fr": "Supprimer", "ru": "Удалить", "jp": "削除", "es": "Eliminar", "zh": "删除"},
    "This fight": {"de": "Diesen Kampf", "fr": "Ce combat", "ru": "Этот бой", "jp": "この戦闘", "es": "Este combate", "zh": "这场战斗"},
    "All fights": {"de": "Alle Kämpfe", "fr": "Tous les combats", "ru": "Все бои", "jp": "すべての戦闘", "es": "Todos los combates", "zh": "所有战斗"},
    "Delete <<1>>? It cannot be brought back.": {"de": "<<1>> löschen? Das kann nicht rückgängig gemacht werden.", "fr": "Supprimer <<1>> ? Cette action est irréversible.", "ru": "Удалить <<1>>? Восстановить его будет нельзя.", "jp": "<<1>>を削除しますか？元に戻せません。", "es": "¿Eliminar <<1>>? No se puede recuperar.", "zh": "删除<<1>>？删除后无法恢复。"},
    "Delete all <<1>> saved fights? They cannot be brought back.": {"de": "Alle <<1>> gespeicherten Kämpfe löschen? Das kann nicht rückgängig gemacht werden.", "fr": "Supprimer les <<1>> combats enregistrés ? Cette action est irréversible.", "ru": "Удалить все сохранённые бои (<<1>>)? Восстановить их будет нельзя.", "jp": "保存された<<1>>件の戦闘をすべて削除しますか？元に戻せません。", "es": "¿Eliminar los <<1>> combates guardados? No se pueden recuperar.", "zh": "删除全部<<1>>场已保存的战斗？删除后无法恢复。"},
    "Penetration from debuffs": {"de": "Durchdringung durch Debuffs", "fr": "Pénétration via les débuffs", "ru": "Пробивание от дебаффов", "jp": "デバフによる貫通", "es": "Penetración por debuffs", "zh": "减益提供的穿透"},
    "Still needed from them": {"de": "Fehlt noch aus eigenen Werten", "fr": "Reste à fournir par le joueur", "ru": "Нужно добрать самому", "jp": "本人が補う必要がある値", "es": "Aún debe aportar el jugador", "zh": "仍需自身补足"},
    "Critical damage from debuffs": {"de": "Kritischer Schaden durch Debuffs", "fr": "Dégâts critiques via les débuffs", "ru": "Критический урон от дебаффов", "jp": "デバフによるクリティカルダメージ", "es": "Daño crítico por debuffs", "zh": "减益提供的暴击伤害"},
    "The game does not share another player's stats. These are what the enemy debuffs added to their hits.": {
        "de": "Das Spiel teilt die Werte anderer Spieler nicht. Dies ist, was die Debuffs auf Gegnern zu ihren Treffern beigetragen haben.",
        "fr": "Le jeu ne partage pas les statistiques des autres joueurs. Voici ce que les débuffs sur les ennemis ont ajouté à leurs coups.",
        "ru": "Игра не передаёт характеристики других игроков. Здесь показано, что дебаффы на врагах добавили к их ударам.",
        "jp": "ゲームは他のプレイヤーのステータスを共有しません。これは敵へのデバフがその攻撃に上乗せした値です。",
        "es": "El juego no comparte las estadísticas de otros jugadores. Esto es lo que los debuffs en los enemigos añadieron a sus golpes.",
        "zh": "游戏不共享其他玩家的属性。这里显示的是敌人身上的减益为其命中提供的加成。",
    },
    "Class mastery": {"de": "Klassenmeisterschaft", "fr": "Maîtrise de classe", "ru": "Мастерство", "jp": "クラスマスタリー", "es": "Maestría de clase", "zh": "职业精通"},
    "Sets seen": {"de": "Erkannte Sets", "fr": "Ensembles observés", "ru": "Замеченные комплекты", "jp": "確認されたセット", "es": "Conjuntos vistos", "zh": "发现的套装"},
    "Buffs seen": {"de": "Erkannte Buffs", "fr": "Buffs observés", "ru": "Замеченные баффы", "jp": "確認されたバフ", "es": "Mejoras vistas", "zh": "发现的增益"},
    "Inferred from the damage, healing and buffs seen in this fight. The game does not share another player's gear or skills.": {
        "de": "Abgeleitet aus Schaden, Heilung und Buffs in diesem Kampf. Das Spiel teilt Ausrüstung und Fertigkeiten anderer Spieler nicht.",
        "fr": "Déduit des dégâts, des soins et des buffs observés dans ce combat. Le jeu ne partage pas l'équipement ni les compétences des autres joueurs.",
        "ru": "Выведено из урона, лечения и баффов в этом бою. Игра не передаёт снаряжение и навыки других игроков.",
        "jp": "この戦闘のダメージ、回復、バフから推定しています。ゲームは他のプレイヤーの装備やスキルを共有しません。",
        "es": "Deducido del daño, la curación y las mejoras vistas en este combate. El juego no comparte el equipo ni las habilidades de otros jugadores.",
        "zh": "根据本场战斗中的伤害、治疗和增益推断。游戏不共享其他玩家的装备或技能。",
    },
    "Champion Points": {"de": "Championpunkte", "fr": "Points de Champion", "ru": "Очки героя", "jp": "チャンピオンポイント", "es": "Puntos de campeón", "zh": "勇士点数"},
    "Stats": {"de": "Werte", "fr": "Stats", "ru": "Показатели", "jp": "ステータス", "es": "Estadísticas", "zh": "属性"},
    "Summary": {"de": "Zusammenfassung", "fr": "Résumé", "ru": "Итог", "jp": "まとめ", "es": "Resumen", "zh": "总览"},
    "Essential enemy debuffs": {"de": "Wichtige Debuffs auf Gegnern", "fr": "Débuffs ennemis essentiels", "ru": "Важные дебаффы на врагах", "jp": "必須の敵デバフ", "es": "Debuffs enemigos esenciales", "zh": "必要的敌人减益"},
    "Essential buffs": {"de": "Wichtige Buffs", "fr": "Buffs essentiels", "ru": "Важные баффы", "jp": "必須バフ", "es": "Mejoras esenciales", "zh": "必要增益"},
    "Missing": {"de": "Fehlt", "fr": "Manquant", "ru": "Нет", "jp": "なし", "es": "Falta", "zh": "缺失"},
    "From enemy debuffs": {"de": "Durch Debuffs auf Gegnern", "fr": "Via les débuffs ennemis", "ru": "От дебаффов на врагах", "jp": "敵へのデバフから", "es": "Por debuffs enemigos", "zh": "来自敌人减益"},
    "With debuffs / cap": {"de": "Mit Debuffs / Limit", "fr": "Avec débuffs / plafond", "ru": "С дебаффами / предел", "jp": "デバフ込み / 上限", "es": "Con debuffs / límite", "zh": "含减益 / 上限"},
    "No skill or buff details were recorded for this fight.": {"de": "Für diesen Kampf wurden keine Fertigkeits- oder Buff-Details aufgezeichnet.", "fr": "Aucun détail de compétence ou de buff n'a été enregistré pour ce combat.", "ru": "Для этого боя не записаны подробности навыков и баффов.", "jp": "この戦闘ではスキルやバフの詳細は記録されませんでした。", "es": "No se registraron detalles de habilidades ni mejoras para este combate.", "zh": "这场战斗没有记录技能或增益详情。"},
    "Records each fight you finish in dungeons, trials, and the open world.": {"de": "Zeichnet jeden Kampf auf, den du in Verliesen, Prüfungen und der offenen Welt beendest.", "fr": "Enregistre chaque combat terminé dans les donjons, les épreuves et le monde ouvert.", "ru": "Записывает каждый завершённый бой в подземельях, испытаниях и открытом мире.", "jp": "ダンジョン、試練、オープンワールドで終えた戦闘をすべて記録します。", "es": "Registra cada combate que terminas en mazmorras, pruebas y el mundo abierto.", "zh": "记录你在地下城、试炼和开放世界中完成的每场战斗。"},
    "No fights recorded yet. Finish a fight and it will appear here.": {"de": "Noch keine Kämpfe aufgezeichnet. Beende einen Kampf, dann erscheint er hier.", "fr": "Aucun combat enregistré pour l'instant. Terminez un combat et il apparaîtra ici.", "ru": "Боёв пока нет. Завершите бой, и он появится здесь.", "jp": "まだ戦闘は記録されていません。戦闘を終えるとここに表示されます。", "es": "Aún no hay combates registrados. Termina un combate y aparecerá aquí.", "zh": "还没有战斗记录。完成一场战斗后会显示在这里。"},
    "Top targets": {"de": "Hauptziele", "fr": "Cibles principales", "ru": "Основные цели", "jp": "主な対象", "es": "Objetivos principales", "zh": "主要目标"},
    "Home": {"de": "Haus", "fr": "Maison", "ru": "Дом", "jp": "家", "es": "Casa", "zh": "房屋"},
    "Performance": {"de": "Leistung", "fr": "Performance", "ru": "Показатели", "jp": "パフォーマンス", "es": "Rendimiento", "zh": "表现"},
    "Character": {"de": "Charakter", "fr": "Personnage", "ru": "Персонаж", "jp": "キャラクター", "es": "Personaje", "zh": "角色"},
    "Sets": {"de": "Sets", "fr": "Ensembles", "ru": "Комплекты", "jp": "セット", "es": "Conjuntos", "zh": "套装"},
    "Critical hits": {"de": "Kritische Treffer", "fr": "Coups critiques", "ru": "Критические удары", "jp": "クリティカル率", "es": "Golpes críticos", "zh": "暴击率"},
    "avg <<1>>": {"de": "Ø <<1>>", "fr": "moy. <<1>>", "ru": "в среднем <<1>>", "jp": "平均<<1>>", "es": "media <<1>>", "zh": "平均<<1>>"},
    "Nobody died.": {"de": "Niemand ist gestorben.", "fr": "Personne n'est mort.", "ru": "Никто не погиб.", "jp": "死亡者はいません。", "es": "Nadie murió.", "zh": "无人死亡。"},
    # Fight Stats Summary: the same terms as the Stats page's damage mix.
    "Direct / over time": {"de": "Direkt / über Zeit", "fr": "Directs / sur la durée", "ru": "Прямой / периодический", "jp": "直接 / 継続", "es": "Directo / en el tiempo", "zh": "直接 / 持续"},
    "Single target / area": {"de": "Einzelziel / Fläche", "fr": "Cible unique / zone", "ru": "Одна цель / область", "jp": "単体 / 範囲", "es": "Objetivo único / área", "zh": "单体 / 范围"},
    "Essential effects": {"de": "Wichtige Effekte", "fr": "Effets essentiels", "ru": "Важные эффекты", "jp": "必須の効果", "es": "Efectos esenciales", "zh": "必要效果"},
    "Potions used": {"de": "Benutzte Tränke", "fr": "Potions utilisées", "ru": "Выпито зелий", "jp": "使用した薬", "es": "Pociones usadas", "zh": "使用的药水"},
    # Fight Stats Group page: "up" is an effect being active, "members" are the
    # group's (not a guild's), and LibGroupCombatStats is a name.
    "Group damage": {"de": "Gruppenschaden", "fr": "Dégâts du groupe", "ru": "Урон группы", "jp": "グループのダメージ", "es": "Daño del grupo", "zh": "队伍伤害"},
    "Your damage": {"de": "Dein Schaden", "fr": "Vos dégâts", "ru": "Ваш урон", "jp": "あなたのダメージ", "es": "Tu daño", "zh": "你的伤害"},
    "Members": {"de": "Mitglieder", "fr": "Membres", "ru": "Участники", "jp": "メンバー", "es": "Miembros", "zh": "成员"},
    "Top DPS": {"de": "Top-DPS", "fr": "Meilleurs DPS", "ru": "Лучший DPS", "jp": "DPS上位", "es": "Mejores DPS", "zh": "最高DPS"},
    "Boss DPS": {"de": "Boss-DPS", "fr": "DPS sur boss", "ru": "DPS по боссу", "jp": "ボスDPS", "es": "DPS a jefes", "zh": "Boss DPS"},
    "HPS with overhealing": {"de": "HPS mit Überheilung", "fr": "HPS avec soins en excès", "ru": "HPS с избыточным лечением", "jp": "オーバーヒール込みHPS", "es": "HPS con sobrecuración", "zh": "含过量治疗的HPS"},
    "Not shared": {"de": "Nicht geteilt", "fr": "Non partagé", "ru": "Не передано", "jp": "共有なし", "es": "No compartido", "zh": "未共享"},
    "Main damage type": {"de": "Hauptschadensart", "fr": "Type de dégâts principal", "ru": "Основной тип урона", "jp": "主なダメージの種類", "es": "Tipo de daño principal", "zh": "主要伤害类型"},
    "<<1>> of <<2>> up": {"de": "<<1>> von <<2>> aktiv", "fr": "<<1>> sur <<2>> actifs", "ru": "<<1>> из <<2>> активны", "jp": "<<1>>/<<2>> 有効", "es": "<<1>> de <<2>> activos", "zh": "<<1>>/<<2>> 生效"},
    "Your healing by target": {"de": "Deine Heilung pro Ziel", "fr": "Vos soins par cible", "ru": "Ваше лечение по целям", "jp": "対象別のあなたの回復", "es": "Tu curación por objetivo", "zh": "你对各目标的治疗"},
    "Other members' DPS and HPS are what their own add-ons share through LibGroupCombatStats at the end of the fight, rounded. A member who runs no add-on that shares them, such as Hodor Reflexes, shows as not shared.": {
        "de": "DPS und HPS der anderen Mitglieder sind das, was ihre eigenen Add-ons am Ende des Kampfes über LibGroupCombatStats teilen, gerundet. Wer kein Add-on nutzt, das sie teilt (etwa Hodor Reflexes), erscheint als nicht geteilt.",
        "fr": "Les DPS et HPS des autres membres sont ce que leurs propres add-ons partagent via LibGroupCombatStats à la fin du combat, arrondis. Un membre sans add-on qui les partage (comme Hodor Reflexes) apparaît comme non partagé.",
        "ru": "DPS и HPS других участников — это то, что их собственные аддоны передают через LibGroupCombatStats в конце боя, с округлением. Участник без аддона, который их передаёт (например, Hodor Reflexes), отмечен как «не передано».",
        "jp": "他のメンバーのDPSとHPSは、戦闘終了時に各自のアドオンがLibGroupCombatStatsで共有する値で、丸められています。共有するアドオン(Hodor Reflexesなど)を使っていないメンバーは「共有なし」と表示されます。",
        "es": "El DPS y el HPS de los demás miembros son lo que sus propios complementos comparten mediante LibGroupCombatStats al final del combate, redondeado. Un miembro sin un complemento que los comparta (como Hodor Reflexes) aparece como no compartido.",
        "zh": "其他成员的DPS和HPS是他们自己的插件在战斗结束时通过LibGroupCombatStats共享的数值，已取整。未使用共享插件（例如Hodor Reflexes）的成员显示为未共享。",
    },
    "The game reports the group's total damage to a target, not each member's part of it.": {
        "de": "Das Spiel meldet nur den Gesamtschaden der Gruppe an einem Ziel, nicht den Anteil jedes Mitglieds.",
        "fr": "Le jeu indique les dégâts totaux du groupe sur une cible, pas la part de chaque membre.",
        "ru": "Игра сообщает только общий урон группы по цели, а не долю каждого участника.",
        "jp": "ゲームが報告するのは対象へのグループ全体のダメージのみで、メンバーごとの内訳はありません。",
        "es": "El juego indica el daño total del grupo a un objetivo, no la parte de cada miembro.",
        "zh": "游戏只报告队伍对目标的总伤害，不提供每个成员的部分。",
    },
    "The game does not share another player's gear or skills. Class skill lines show when they run an add-on that shares them through LibGroupCombatStats, and gear sets when their buffs point to one.": {
        "de": "Das Spiel teilt Ausrüstung und Fertigkeiten anderer Spieler nicht. Klassenfertigkeitslinien erscheinen, wenn sie ein Add-on nutzen, das sie über LibGroupCombatStats teilt, und Sets, wenn ihre Buffs auf ein Set hinweisen.",
        "fr": "Le jeu ne partage pas l'équipement ni les compétences des autres joueurs. Les lignes de compétences de classe s'affichent quand ils utilisent un add-on qui les partage via LibGroupCombatStats, et les ensembles quand leurs buffs en révèlent un.",
        "ru": "Игра не передаёт снаряжение и навыки других игроков. Классовые ветки навыков видны, если у игрока есть аддон, который передаёт их через LibGroupCombatStats, а комплекты — если на них указывают его баффы.",
        "jp": "ゲームは他のプレイヤーの装備やスキルを共有しません。クラスのスキルラインは、LibGroupCombatStatsで共有するアドオンを使っている場合に、セットはバフからセットが分かる場合に表示されます。",
        "es": "El juego no comparte el equipo ni las habilidades de otros jugadores. Las líneas de habilidades de clase aparecen si usan un complemento que las comparte mediante LibGroupCombatStats, y los conjuntos cuando sus mejoras delatan uno.",
        "zh": "游戏不共享其他玩家的装备或技能。当对方使用通过LibGroupCombatStats共享的插件时会显示职业技能线，当其增益能对应到某个套装时会显示该套装。",
    },
    # PersonalAssistant banking rules: "Bag" is where the items are kept, the
    # comparisons read "<bag> keeps at least <quantity>", and PersonalAssistant
    # is a name. Junk is the game's term (SI_ITEMFILTERTYPE9).
    "Bag": {"de": "Lagerort", "fr": "Emplacement", "ru": "Хранилище", "jp": "保管場所", "es": "Ubicación", "zh": "存放位置"},
    "Keeps": {"de": "Enthält", "fr": "Contient", "ru": "Содержит", "jp": "所持数", "es": "Contiene", "zh": "持有"},
    "Exactly": {"de": "Genau", "fr": "Exactement", "ru": "Ровно", "jp": "ちょうど", "es": "Exactamente", "zh": "正好"},
    "At most": {"de": "Höchstens", "fr": "Au plus", "ru": "Не более", "jp": "最大", "es": "Como máximo", "zh": "最多"},
    "At least": {"de": "Mindestens", "fr": "Au moins", "ru": "Не менее", "jp": "最低", "es": "Al menos", "zh": "至少"},
    "Add rule": {"de": "Regel hinzufügen", "fr": "Ajouter la règle", "ru": "Добавить правило", "jp": "ルールを追加", "es": "Añadir regla", "zh": "添加规则"},
    "Update rule": {"de": "Regel aktualisieren", "fr": "Mettre à jour la règle", "ru": "Обновить правило", "jp": "ルールを更新", "es": "Actualizar regla", "zh": "更新规则"},
    "Delete rule": {"de": "Regel löschen", "fr": "Supprimer la règle", "ru": "Удалить правило", "jp": "ルールを削除", "es": "Eliminar regla", "zh": "删除规则"},
    "PersonalAssistant integration": {"de": "PersonalAssistant-Integration", "fr": "Intégration de PersonalAssistant", "ru": "Интеграция с PersonalAssistant", "jp": "PersonalAssistant連携", "es": "Integración con PersonalAssistant", "zh": "PersonalAssistant 集成"},
    "Adds PersonalAssistant actions to the gamepad inventory actions prompt when PersonalAssistant is installed: mark or unmark as permanent junk, and add, edit, or delete a custom banking rule. Each appears only when that kind of rule is turned on in PersonalAssistant.": {
        "de": "Fügt dem Aktionsmenü des Gamepad-Inventars PersonalAssistant-Aktionen hinzu, wenn PersonalAssistant installiert ist: dauerhaft als Trödel markieren oder die Markierung aufheben sowie eine eigene Bankregel hinzufügen, bearbeiten oder löschen. Jede Aktion erscheint nur, wenn diese Art von Regel in PersonalAssistant aktiviert ist.",
        "fr": "Ajoute des actions PersonalAssistant au menu d'actions de l'inventaire à la manette quand PersonalAssistant est installé : mettre ou retirer définitivement aux rebuts, et ajouter, modifier ou supprimer une règle bancaire personnalisée. Chaque action n'apparaît que si ce type de règle est activé dans PersonalAssistant.",
        "ru": "Добавляет действия PersonalAssistant в меню действий инвентаря на геймпаде, если установлен PersonalAssistant: пометить как постоянный хлам или снять пометку, а также добавить, изменить или удалить своё банковское правило. Каждое действие появляется, только если такие правила включены в PersonalAssistant.",
        "jp": "PersonalAssistantがインストールされている場合、ゲームパッドのインベントリのアクションメニューにPersonalAssistantのアクションを追加します。永続的なガラクタとしてマーク/解除と、カスタム銀行ルールの追加・編集・削除です。それぞれ、PersonalAssistantでその種類のルールが有効な場合にのみ表示されます。",
        "es": "Añade acciones de PersonalAssistant al menú de acciones del inventario con mando cuando PersonalAssistant está instalado: marcar o desmarcar como basura permanente, y añadir, editar o eliminar una regla bancaria personalizada. Cada acción solo aparece si ese tipo de regla está activado en PersonalAssistant.",
        "zh": "安装PersonalAssistant后，在手柄背包的操作菜单中添加PersonalAssistant操作：标记或取消永久废品，以及添加、编辑或删除自定义银行规则。仅当PersonalAssistant中启用了对应类型的规则时才会显示。",
    },
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
