#!/usr/bin/env python3
"""Chequeos de coherencia del paquete de diseño ProveeEventos.

Uso (desde la raíz del proyecto):
    python3 -I Tools/check_package.py            # todos los chequeos
    python3 -I Tools/check_package.py --only 1,3 # solo algunos

Chequeos:
  1. Marcas de estado de decisiones. El conjunto de decisiones pendientes se
     calcula: filas de Decisiones.md §7 con estado "Pendiente de aprobación"
     (admite rangos como "TEC-006–012") y ADR del SAD cuyo "**Estado:**"
     dice "pendiente". Entonces:
       a) toda línea que cite una decisión pendiente contiene "pendiente";
       b) ninguna línea que cite solo decisiones aprobadas conserva una marca
          de pendiente ("(pendiente)", ", pendiente", "pendiente de
          aprobación"), salvo las filas de historial de versiones.
     Se revisan CLAUDE.md, PRD, SRS, SAD, DDD, YAML, Trazabilidad y Glosario.
     Decisiones.md queda fuera: es donde se definen.
  2. Matriz PRD <-> SRS (SRS §12), en las dos direcciones: cada RF-*/RNF-*
     citado existe en el PRD y cada uno del PRD está en la matriz; cada SRS-*
     citado está definido y cada requisito SRS (funcional o no funcional)
     está en la matriz.
  3. operationIds: cada operationId del YAML aparece en Trazabilidad.md y
     cada operationId citado en Trazabilidad.md existe en el YAML.
  4. Requisitos: cada SRS-* definido (encabezado ###) tiene fila en
     Trazabilidad.md y cada fila corresponde a un requisito definido.
  5. Eventos: cada evento del catálogo DDD §8.1 aparece en Trazabilidad.md.
  6. Entregas: las etiquetas E1/E2 de cada requisito coinciden entre el SRS y
     Trazabilidad.md, en el mismo orden de primera aparición (la primera es
     la entrega principal).
  7. IDs de decisión: todo DEC-*, TEC-* y ADR-* citado está definido
     (DEC/TEC en Decisiones.md, ADR en el SAD).
  8. Jobs: cada job programado de SAD §8.2 aparece, con su nombre exacto, en
     una anotación "(job: ...)" de Trazabilidad.md (varios se separan con
     ";") y cada nombre anotado es un job de SAD §8.2.
  9. Versiones: las referencias a la versión vigente de un documento (CLAUDE.md,
     encabezados, pies y Trazabilidad.md) coinciden con la cabecera de ese
     documento, y la cabecera coincide con la última fila de su historial.

Limitaciones aceptadas (Review V3, M-18 y M-19):
  - Los chequeos 3, 5 y 8 verifican presencia, no que el operationId, evento o
    job esté en la fila del requisito correcto: no hay una segunda fuente
    legible por máquina con esa correspondencia. Se revisa al editar la matriz.
  - El chequeo 6 no interpreta a qué sub-alcance se refiere cada etiqueta.
  - El chequeo 1 reconoce solo las formas de marca que fija CLAUDE.md;
    "pendiente" es además una palabra del dominio.

Sale con 1 si algún chequeo falla, 0 si todos pasan. Sin dependencias
externas.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PRD = ROOT / "ProveeEventos_PRD.md"
SRS = ROOT / "ProveeEventos_SRS.md"
SAD = ROOT / "ProveeEventos_SAD.md"
DDD = ROOT / "ProveeEventos_DDD.md"
API = ROOT / "ProveeEventos_API_Spec.yaml"
DEC = ROOT / "Decisiones.md"
TRZ = ROOT / "Trazabilidad.md"
GLO = ROOT / "Glosario.md"
CLA = ROOT / "CLAUDE.md"

DECISION_ID = re.compile(r"\b((?:DEC|TEC|ADR)-\d{3})\b")
STALE_MARK = re.compile(r"\(pendientes?\)|, pendientes?\b|pendientes? de aprobación", re.I)
HISTORY_ROW = re.compile(r"^\| \d+\.\d+(?:\.\d+)?(?: \(rev\.\))? \|")


def lines(path):
    return path.read_text(encoding="utf-8").split("\n")


def rel(path):
    return path.relative_to(ROOT)


def pending_ids():
    """Decisiones pendientes según Decisiones.md §7 y los ADR del SAD."""
    pending = set()
    for line in lines(DEC):
        if line.startswith("| ") and "pendiente de aprobación" in line.lower():
            first = line.split("|")[1]
            for pre, a, b in re.findall(r"(DEC|TEC|ADR)-(\d{3})(?:[–-](\d{3}))?", first):
                for i in range(int(a), int(b or a) + 1):
                    pending.add(f"{pre}-{i:03d}")
    current = None
    for line in lines(SAD):
        m = re.match(r"^## (ADR-\d{3})\b", line)
        if m:
            current = m.group(1)
        elif current and line.startswith("**Estado:**"):
            if "pendiente" in line.lower():
                pending.add(current)
            current = None
    return pending


def check_pending():
    errs, pending = [], pending_ids()
    for path in (CLA, PRD, SRS, SAD, DDD, API, TRZ, GLO):
        for n, line in enumerate(lines(path), 1):
            ids = set(DECISION_ID.findall(line))
            if not ids:
                continue
            cited = ids & pending
            if cited and "pendiente" not in line.lower():
                errs.append(f"{rel(path)}:{n}: {','.join(sorted(cited))} sin marca de pendiente")
            elif not cited and STALE_MARK.search(line) and not HISTORY_ROW.match(line):
                errs.append(f"{rel(path)}:{n}: marca de pendiente en decisión aprobada "
                            f"({','.join(sorted(ids))})")
    return errs


def prd_ids():
    text = PRD.read_text(encoding="utf-8")
    return set(re.findall(r"^\| (RN?F-(?:[A-Z]+-)?\d+) \|", text, re.M))


def expand(token):
    """RF-CAT-01..08 -> [RF-CAT-01..RF-CAT-08]; RNF-06..11 -> RNF-06..RNF-11."""
    m = re.fullmatch(r"(RN?F-(?:[A-Z]+-)?)(\d+)(?:\.\.(\d+))?", token)
    if not m:
        return []
    pre, a, b = m.group(1), m.group(2), m.group(3) or m.group(2)
    width = len(a)
    return [f"{pre}{i:0{width}d}" for i in range(int(a), int(b) + 1)]


def section(path, start_pat, end_pat=r"^# "):
    out, inside = [], False
    for n, line in enumerate(lines(path), 1):
        if re.match(start_pat, line):
            inside = True
            continue
        if inside and re.match(end_pat, line):
            break
        if inside:
            out.append((n, line))
    return out


def check_matrix():
    errs, known = [], prd_ids()
    srs_known = set(srs_defined()) | set(re.findall(
        r"^\| (SRS-NFR-[A-Z]+-\d{3}) \|", SRS.read_text(encoding="utf-8"), re.M))
    rows = section(SRS, r"^# 12\. ")
    if not rows:
        return [f"{rel(SRS)}: no se encontró la sección 12"]
    prd_covered, srs_covered = set(), set()
    for n, line in rows:
        if not line.startswith("| "):
            continue
        cells = line.split("|")
        for tok in re.findall(r"RN?F-(?:[A-Z]+-)?\d+(?:\.\.\d+)?", cells[1]):
            for rid in expand(tok):
                prd_covered.add(rid)
                if rid not in known:
                    errs.append(f"{rel(SRS)}:{n}: {rid} no existe en el PRD")
        col = cells[2] if len(cells) > 2 else ""
        for pre, a, b in re.findall(r"\b(SRS(?:-[A-Z]+)+-)(\d{3})(?:\.\.(\d{3}))?", col):
            for i in range(int(a), int(b or a) + 1):
                rid = f"{pre}{i:03d}"
                srs_covered.add(rid)
                if rid not in srs_known:
                    errs.append(f"{rel(SRS)}:{n}: {rid} citado en la matriz y no definido")
    for rid in sorted(known - prd_covered):
        errs.append(f"{rel(PRD)}: {rid} ausente de la matriz del SRS §12")
    for rid in sorted(srs_known - srs_covered):
        errs.append(f"{rel(SRS)}: {rid} ausente de la matriz del SRS §12")
    return errs


def api_operation_ids():
    return re.findall(r"^\s+operationId:\s*([A-Za-z0-9_]+)\s*$",
                      API.read_text(encoding="utf-8"), re.M)


def trz_rows():
    rows = {}
    for n, line in enumerate(lines(TRZ), 1):
        m = re.match(r"^\| (SRS-[A-Z]+(?:-[A-Z]+)?-\d+) \|", line)
        if m:
            cells = [c.strip() for c in line.split("|")[1:-1]]
            rows[m.group(1)] = (n, cells)
    return rows


def check_operations():
    errs = []
    ops = set(api_operation_ids())
    rows = trz_rows()
    cited = set()
    for rid, (n, cells) in rows.items():
        col = cells[3] if len(cells) > 3 else ""
        col = re.sub(r"\([^)]*\)", "", col)  # quita justificaciones
        for word in re.findall(r"\b[a-z][A-Za-z0-9]+\b", col):
            if any(ch.isupper() for ch in word):
                cited.add(word)
                if word not in ops:
                    errs.append(f"{rel(TRZ)}:{n}: operationId {word} no existe en el YAML")
    for op in sorted(ops - cited):
        errs.append(f"{rel(API)}: operationId {op} sin fila en Trazabilidad.md")
    return errs


def srs_defined():
    out = {}
    for n, line in enumerate(lines(SRS), 1):
        m = re.match(r"^### (SRS-[A-Z]+(?:-[A-Z]+)?-\d+)\b", line)
        if m:
            out[m.group(1)] = n
    return out


def check_requirements():
    errs = []
    defined, rows = srs_defined(), trz_rows()
    for rid in sorted(set(defined) - set(rows)):
        errs.append(f"{rel(SRS)}:{defined[rid]}: {rid} sin fila en Trazabilidad.md")
    for rid in sorted(set(rows) - set(defined)):
        errs.append(f"{rel(TRZ)}:{rows[rid][0]}: {rid} no está definido en el SRS")
    return errs


def check_events():
    errs = []
    trz = TRZ.read_text(encoding="utf-8")
    for n, line in section(DDD, r"^## 8\.1 ", r"^## "):
        m = re.match(r"^\| `([A-Z][A-Za-z]+)` \|", line)
        if m and not re.search(r"\b" + m.group(1) + r"\b", trz):
            errs.append(f"{rel(DDD)}:{n}: evento {m.group(1)} sin aparición en Trazabilidad.md")
    return errs


def deliveries(text):
    """Etiquetas E1/E2 sin repetir, en orden de primera aparición."""
    return tuple(dict.fromkeys(re.findall(r"\bE[12]\b", text)))


def check_deliveries():
    errs = []
    srs_lines = lines(SRS)
    labels = {}
    for rid, n in srs_defined().items():
        for line in srs_lines[n:n + 4]:
            if line.startswith("**Entrega:**"):
                labels[rid] = (n, deliveries(line))
                break
        else:
            errs.append(f"{rel(SRS)}:{n}: {rid} sin línea **Entrega:**")
    for rid, (n, cells) in trz_rows().items():
        if rid in labels and len(cells) > 5:
            if deliveries(cells[5]) != labels[rid][1]:
                errs.append(
                    f"{rel(TRZ)}:{n}: {rid} entrega '{cells[5]}' distinta del SRS "
                    f"({'/'.join(labels[rid][1])}, SRS:{labels[rid][0]})"
                )
    return errs


def check_decision_ids():
    errs = []
    dec_text = DEC.read_text(encoding="utf-8")
    sad_text = SAD.read_text(encoding="utf-8")
    defined = set(re.findall(r"^## ((?:DEC|TEC)-\d{3})\b", dec_text, re.M))
    defined |= set(re.findall(r"^## (ADR-\d{3})\b", sad_text, re.M))
    for path in (CLA, PRD, SRS, SAD, DDD, API, DEC, TRZ, GLO):
        for n, line in enumerate(lines(path), 1):
            for rid in re.findall(r"\b((?:DEC|TEC|ADR)-\d{3})\b", line):
                if rid not in defined:
                    errs.append(f"{rel(path)}:{n}: {rid} citado pero no definido")
            # rangos DEC-019..034: comprobar extremos
            for pre, a, b in re.findall(r"\b(DEC|TEC|ADR)-(\d{3})\.\.(\d{3})\b", line):
                for x in (a, b):
                    if f"{pre}-{x}" not in defined:
                        errs.append(f"{rel(path)}:{n}: {pre}-{x} (extremo de rango) no definido")
    return errs


def sad_jobs():
    """Nombres de la tabla de jobs programados de SAD §8.2."""
    jobs, inside = {}, False
    for n, line in section(SAD, r"^## 8\.2 ", r"^## "):
        if line.startswith("| Job |"):
            inside = True
        elif inside and not line.startswith("|"):
            break
        elif inside and not line.startswith("|---"):
            jobs[line.split("|")[1].strip().casefold()] = n
    return jobs


def check_jobs():
    jobs = sad_jobs()
    if not jobs:
        return [f"{rel(SAD)}: no se encontró la tabla de jobs de §8.2"]
    errs, noted = [], set()
    for n, line in enumerate(lines(TRZ), 1):
        if not line.startswith("| SRS-"):
            continue
        for group in re.findall(r"\(job: ([^)]*)\)", line):
            for name in (x.strip() for x in group.split(";")):
                noted.add(name.casefold())
                if name.casefold() not in jobs:
                    errs.append(f"{rel(TRZ)}:{n}: job '{name}' no está en SAD §8.2")
    for name, n in jobs.items():
        if name not in noted:
            errs.append(f"{rel(SAD)}:{n}: job '{name}' sin anotación en Trazabilidad.md")
    return errs


VERSION_REF = re.compile(  # admite "SRS v1.3" y "`ProveeEventos_SRS.md` v1.3"
    r"(?<![A-Za-z])(PRD|SRS|SAD|DDD|API|Decisiones)(?:\.md`?)? v?(\d+\.\d+(?:\.\d+)?)")


def check_versions():
    errs, current = [], {}
    for key, path in (("PRD", PRD), ("SRS", SRS), ("SAD", SAD), ("DDD", DDD),
                      ("Decisiones", DEC)):
        text = path.read_text(encoding="utf-8")
        head = re.search(r"^\*\*Versión:\*\* (\d+\.\d+)", text, re.M)
        if not head:
            errs.append(f"{rel(path)}: sin cabecera **Versión:**")
            continue
        current[key] = head.group(1)
        history = re.findall(r"^\| (\d+\.\d+)(?: \(rev\.\))? \| \d{2}-\d{2}-\d{4} \|",
                             text, re.M)
        if not history or history[-1] != head.group(1):
            errs.append(f"{rel(path)}: cabecera {head.group(1)} distinta de la última "
                        f"fila del historial ({history[-1] if history else 'ninguna'})")
    api = re.search(r"^  version: (\d+\.\d+\.\d+)", API.read_text(encoding="utf-8"), re.M)
    if not api:
        return errs + [f"{rel(API)}: sin info.version"]
    current["API"] = api.group(1)

    # (archivo, patrón que identifica la línea, obligatoria)
    anchors = (
        (CLA, r"Versiones vigentes:", True),
        (CLA, r"contrato HTTP \(OpenAPI", True),
        (SRS, r"^\*\*Documento de origen:\*\*", True),
        (SRS, r"^\| Fuente normativa del producto \|", True),
        (SAD, r"^\*\*Documentos de entrada:\*\*", True),
        (DDD, r"^\*\*Estado:\*\* Modelo de dominio", True),
        (DDD, r"^\| Documento rector de producto \|", True),
        (DDD, r"^\| Especificación de comportamiento \|", True),
        (DDD, r"^\| Arquitectura de referencia \|", True),
        (API, r"Contrato REST/JSON del MVP derivado", True),
        (TRZ, r"Se genera a partir de", True),
        (PRD, r"Fin del documento", False),
        (SRS, r"Fin del documento", False),
        (SAD, r"Fin del documento", False),
        (DDD, r"Fin del documento", False),
    )
    for path, pattern, required in anchors:
        found = False
        for n, line in enumerate(lines(path), 1):
            if not re.search(pattern, line):
                continue
            found = True
            if path == CLA and "contrato HTTP" in line:
                refs = [("API", v) for v in re.findall(r"versión (\d+\.\d+\.\d+)", line)]
            else:
                refs = VERSION_REF.findall(line)
                refs += [("API", v) for v in
                         re.findall(r"contrato (\d+\.\d+\.\d+)", line)]
            for key, ver in refs:
                if key == "API" and ver.count(".") != 2:
                    continue  # "OpenAPI 3.1" es la versión del estándar
                if current.get(key) != ver:
                    errs.append(f"{rel(path)}:{n}: cita {key} {ver}; la vigente es "
                                f"{current.get(key)}")
        if required and not found:
            errs.append(f"{rel(path)}: no se encontró la línea '{pattern}'")
    return errs


CHECKS = {
    1: ("Marcas de estado de decisiones", check_pending),
    2: ("Matriz PRD <-> SRS", check_matrix),
    3: ("operationIds <-> Trazabilidad", check_operations),
    4: ("Requisitos SRS <-> Trazabilidad", check_requirements),
    5: ("Eventos DDD §8.1 en Trazabilidad", check_events),
    6: ("Entregas SRS <-> Trazabilidad", check_deliveries),
    7: ("IDs DEC/TEC/ADR definidos", check_decision_ids),
    8: ("Jobs SAD §8.2 <-> Trazabilidad", check_jobs),
    9: ("Versiones declaradas", check_versions),
}


def main(argv):
    only = None
    if "--only" in argv:
        i = argv.index("--only")
        only = {int(x) for x in argv[i + 1].split(",")}
    failed = 0
    for num, (name, fn) in CHECKS.items():
        if only and num not in only:
            continue
        errs = fn()
        status = "OK" if not errs else f"{len(errs)} fallo(s)"
        print(f"[{num}] {name}: {status}")
        for e in errs:
            print("    " + e)
        failed += bool(errs)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
