#!/usr/bin/env python3
"""
Genera el paquete de criaturas `public/packs/tuxemon/` a partir de un clon del
repositorio de Tuxemon (https://github.com/Tuxemon/Tuxemon).

Los sprites de Tuxemon se distribuyen bajo CC BY-SA 4.0 (algunos CC BY 4.0).
Este script copia las hojas de sprites, traduce los datos al formato del juego
y deja CREDITS.md con la atribución que exige la licencia.

Uso:
    python tools/build_pack_tuxemon.py <ruta_al_clon_de_tuxemon> [salida]

Clon mínimo (sparse) del repositorio:
    git clone --depth 1 --filter=blob:none --sparse https://github.com/Tuxemon/Tuxemon.git tuxemon
    cd tuxemon
    git sparse-checkout set --no-cone /ATTRIBUTIONS.md /mods/tuxemon/gfx/sprites/battle/ \
        /mods/tuxemon/db/monster/ /mods/tuxemon/db/shape/ /mods/tuxemon/db/element/ \
        /mods/tuxemon/l18n/es_ES/
"""
import json
import os
import re
import shutil
import sys

try:
    import yaml
except ImportError:  # pragma: no cover
    sys.exit("Falta PyYAML: pip install pyyaml")

SRC = sys.argv[1] if len(sys.argv) > 1 else "tuxemon"
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(
    os.path.dirname(__file__), "..", "public", "packs", "tuxemon")

MOD = os.path.join(SRC, "mods", "tuxemon")
SHEETS = os.path.join(MOD, "gfx", "sprites", "battle")

# ---------------------------------------------------------------- traducciones
def load_po(path):
    """Lee un .po sencillo (msgid/msgstr, con cadenas multilínea)."""
    out, key, val, mode = {}, None, [], None
    if not os.path.exists(path):
        return out
    for raw in open(path, encoding="utf-8"):
        line = raw.strip()
        if line.startswith("msgid "):
            if key is not None:
                out[key] = "".join(val)
            key, val, mode = json.loads(line[6:]), [], "id"
        elif line.startswith("msgstr "):
            val, mode = [json.loads(line[7:])], "str"
        elif line.startswith('"') and mode == "str":
            val.append(json.loads(line))
        elif line.startswith('"') and mode == "id":
            key += json.loads(line)
    if key is not None:
        out[key] = "".join(val)
    return out


po = load_po(os.path.join(MOD, "l18n", "es_ES", "LC_MESSAGES", "base.po"))


def tr(slug, fallback=None):
    v = po.get(slug)
    return v if v else (fallback or slug.replace("_", " ").title())


# ---------------------------------------------------------------- formas y tipos
shapes = {s["slug"]: s["attributes"] for s in yaml.safe_load(
    open(os.path.join(MOD, "db", "shape", "shapes.yaml"), encoding="utf-8"))}

TYPE_ES = {"cosmic": "Cósmico", "earth": "Tierra", "fire": "Fuego", "frost": "Hielo",
           "heroic": "Heroico", "lightning": "Rayo", "metal": "Metal", "normal": "Normal",
           "shadow": "Sombra", "sky": "Cielo", "venom": "Veneno", "water": "Agua", "wood": "Madera"}

elements = {}
for f in sorted(os.listdir(os.path.join(MOD, "db", "element"))):
    if f.endswith(".yaml"):
        d = yaml.safe_load(open(os.path.join(MOD, "db", "element", f), encoding="utf-8"))
        elements[d["slug"]] = {
            "name": TYPE_ES.get(d["slug"], tr(d["slug"])),
            "vs": {t["against"]: t["multiplier"] for t in d.get("types", [])},
        }

# ---------------------------------------------------------------- créditos
attr_lines = open(os.path.join(SRC, "ATTRIBUTIONS.md"), encoding="utf-8").read().split("\n")
start = next(i for i, l in enumerate(attr_lines) if l.strip() == "### Tuxemon")
end = next(i for i in range(start + 1, len(attr_lines)) if attr_lines[i].startswith("### "))
section = "\n".join(attr_lines[start:end]).strip()
entries = [e.strip() for e in re.split(r"\n(?=\* \[)", section) if e.strip().startswith("* [")]
credit_by_slug = {}
for e in entries:
    for name in re.findall(r'\["([^"]+)"\]', e):
        slug = name.lower().replace(" ", "_").replace("-", "_")
        credit_by_slug.setdefault(slug, " ".join(e[2:].split()))

# ---------------------------------------------------------------- especies
STAGE_MULT = {"basic": 1.0, "stage1": 1.15, "stage2": 1.3, "standalone": 1.2}


def rarity(stage, stat_sum):
    if stage == "basic":
        return "comun"
    if stage == "stage1":
        return "raro"
    if stage == "stage2":
        return "especial"
    return "especial" if stat_sum >= 38 else "raro"


os.makedirs(os.path.join(OUT, "sprites"), exist_ok=True)
species = []
for f in sorted(os.listdir(os.path.join(MOD, "db", "monster"))):
    if not f.endswith(".yaml"):
        continue
    d = yaml.safe_load(open(os.path.join(MOD, "db", "monster", f), encoding="utf-8"))
    slug = d["slug"]
    sheet = os.path.join(SHEETS, f"{slug}-sheet.png")
    if not os.path.exists(sheet):
        continue
    shape = shapes.get(d.get("shape"), shapes["blob"])
    stage = d.get("stage", "basic")
    m = STAGE_MULT.get(stage, 1.0)
    ranged = shape["ranged"] > shape["melee"]
    stat_sum = sum(shape.values())
    evo = next(iter(d.get("evolutions") or []), None)
    shutil.copyfile(sheet, os.path.join(OUT, "sprites", f"{slug}.png"))
    species.append({
        "slug": slug,
        "name": tr(slug),
        "dexId": d.get("txmn_id"),
        "types": d.get("types", ["normal"]),
        "stage": stage,
        "rarity": rarity(stage, stat_sum),
        "shape": d.get("shape"),
        "base": {
            "hp": round((60 + shape["hp"] * 10) * m),
            "atk": round((10 + max(shape["melee"], shape["ranged"]) * 2) * m),
            "def": round((5 + shape["armour"] * 2) * m),
            "spd": round(40 + shape["speed"] * 10),
            "dodge": round(shape["dodge"] * 1.5, 1),
            "range": 260 if ranged else 110,
        },
        "evolvesTo": ({"slug": evo["monster_slug"], "level": evo.get("at_level")}
                      if evo and evo.get("at_level") else None),
        "description": tr(f"{slug}_description", ""),
        "credit": credit_by_slug.get(slug) or
                  f"Tuxemon project contributors — https://wiki.tuxemon.org/{tr(slug).replace(' ', '_')}",
        "creditVerified": slug in credit_by_slug,
    })

slugs = {s["slug"] for s in species}
for s in species:  # evoluciones hacia especies sin sprite se descartan
    if s["evolvesTo"] and s["evolvesTo"]["slug"] not in slugs:
        s["evolvesTo"] = None

pack = {
    "id": "tuxemon",
    "name": "Tuxemon",
    "license": "CC BY-SA 4.0 (algunos sprites CC BY 4.0)",
    "source": "https://github.com/Tuxemon/Tuxemon",
    "noun": "criaturas",
    "format": 1,
    "sheet": {"front": [0, 0, 64, 64], "back": [64, 0, 64, 64],
              "menu": [[0, 64, 24, 24], [24, 64, 24, 24]]},
    "species": species,
}
json.dump(pack, open(os.path.join(OUT, "species.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump(elements, open(os.path.join(OUT, "elements.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=1)
json.dump({"vfx": {}, "backgrounds": [], "audio": {"bgm": {}, "sfx": {}}},
          open(os.path.join(OUT, "assets.json"), "w", encoding="utf-8"), indent=1)

with open(os.path.join(OUT, "CREDITS.md"), "w", encoding="utf-8") as c:
    c.write("# Créditos del paquete de criaturas\n\n")
    c.write("Sprites y datos de criaturas del proyecto **Tuxemon** "
            "(https://github.com/Tuxemon/Tuxemon), licenciados bajo "
            "[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) "
            "salvo donde se indica otra licencia.\n\n")
    c.write("Las hojas de sprites se copian sin modificar. Si se modifican, las versiones "
            "modificadas deben publicarse bajo la misma licencia (CC BY-SA 4.0).\n\n")
    c.write("Créditos individuales de cada criatura: página de la criatura en "
            "https://wiki.tuxemon.org/ y el archivo ATTRIBUTIONS.md del proyecto.\n\n")
    c.write("## Atribuciones listadas en ATTRIBUTIONS.md de Tuxemon\n\n")
    c.write(section.replace("### Tuxemon", "").strip() + "\n")

counts = {}
for s in species:
    counts[s["rarity"]] = counts.get(s["rarity"], 0) + 1
print(f"{len(species)} especies -> {OUT}  {counts}  "
      f"créditos explícitos: {sum(s['creditVerified'] for s in species)}")
