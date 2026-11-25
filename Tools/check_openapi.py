#!/usr/bin/env python3
"""Validación básica de un contrato OpenAPI 3.x en YAML.

Uso: python3 -I Tools/check_openapi.py ProveeEventos_API_Spec.yaml

Comprueba: $ref locales resolubles, operationId presentes y únicos,
respuestas 4xx por operación, Idempotency-Key en POST, operaciones públicas
(security efectiva vacía) y additionalProperties: true alcanzables desde
respuestas. Sale con 1 si hay $ref rotos u operationId ausentes/duplicados;
0 en otro caso. Sale con 2 si el fichero no se puede leer o parsear.
"""
import sys
from urllib.parse import unquote

import yaml

METHODS = ("get", "post", "put", "patch", "delete")
MISSING = object()


def iter_nodes(node, path=""):
    """Recorre recursivamente dicts y listas. Devuelve (puntero JSON, nodo)."""
    yield path, node
    if isinstance(node, dict):
        for k, v in node.items():
            seg = str(k).replace("~", "~0").replace("/", "~1")
            yield from iter_nodes(v, f"{path}/{seg}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from iter_nodes(v, f"{path}/{i}")


def collect_refs(node):
    """Devuelve (puntero, ref) de todos los $ref dentro del subárbol."""
    out = []
    for p, n in iter_nodes(node):
        if isinstance(n, dict) and isinstance(n.get("$ref"), str):
            out.append((p, n["$ref"]))
    return out


def resolve(doc, ref):
    """Resuelve un $ref local '#/...'. Devuelve MISSING si no resuelve."""
    if not isinstance(ref, str) or not ref.startswith("#/"):
        return MISSING
    node = doc
    for part in ref[2:].split("/"):
        part = unquote(part).replace("~1", "/").replace("~0", "~")
        if isinstance(node, dict) and part in node:
            node = node[part]
        elif isinstance(node, list) and part.isdigit() and int(part) < len(node):
            node = node[int(part)]
        else:
            return MISSING
    return node


def ref_name(ref):
    return ref.rsplit("/", 1)[-1]


def is_idempotency_param(raw, doc):
    """Comprueba si un parámetro (inline o $ref) es Idempotency-Key."""
    if isinstance(raw, dict) and "$ref" in raw:
        ref = raw["$ref"]
        target = resolve(doc, ref)
        if "idempotency" in ref_name(ref).lower():
            return True
        return isinstance(target, dict) and target.get("name") == "Idempotency-Key"
    return isinstance(raw, dict) and raw.get("name") == "Idempotency-Key"


def reachable_refs(doc, roots):
    """Conjunto de refs de components alcanzables desde los nodos 'roots'."""
    seen = set()
    queue = [r for _, r in collect_refs(roots)]
    while queue:
        ref = queue.pop()
        if ref in seen:
            continue
        seen.add(ref)
        target = resolve(doc, ref)
        if target is not MISSING:
            queue.extend(r for _, r in collect_refs(target))
    return seen


def main(argv):
    if len(argv) != 2:
        print("Uso: python3 -I Tools/check_openapi.py <fichero.yaml>", file=sys.stderr)
        return 2
    path = argv[1]
    try:
        with open(path, encoding="utf-8") as fh:
            doc = yaml.safe_load(fh)
    except (OSError, yaml.YAMLError) as exc:
        print(f"ERROR: no se pudo cargar {path}: {exc}", file=sys.stderr)
        return 2
    if not isinstance(doc, dict):
        print("ERROR: el documento raíz no es un mapa YAML", file=sys.stderr)
        return 2

    info = doc.get("info") or {}
    paths = doc.get("paths") or {}
    global_security = doc.get("security")

    # Operaciones: (método, path, path_item, operación)
    operations = []
    for p, item in paths.items():
        if not isinstance(item, dict):
            continue
        for m in METHODS:
            if m in item and isinstance(item[m], dict):
                operations.append((m, str(p), item, item[m]))

    print(f"openapi: {doc.get('openapi')}")
    print(f"info.version: {info.get('version')}")
    print(f"paths: {len(paths)}")
    counts = {m: 0 for m in METHODS}
    for m, _, _, _ in operations:
        counts[m] += 1
    print("operaciones: " + str(len(operations)) + " ("
          + ", ".join(f"{m}={counts[m]}" for m in METHODS) + ")")
    print()

    # 1. $ref locales
    broken_refs = []
    external_refs = 0
    for p, node in iter_nodes(doc):
        if isinstance(node, dict) and isinstance(node.get("$ref"), str):
            ref = node["$ref"]
            if not ref.startswith("#"):
                external_refs += 1
            elif resolve(doc, ref) is MISSING:
                broken_refs.append((p or "/", ref))
    print(f"== $ref locales rotos: {len(broken_refs)} (refs externas no verificadas: {external_refs})")
    for p, ref in broken_refs:
        print(f"  - {p} -> {ref}")
    print()

    # 2. operationId
    missing_opid = []
    opid_map = {}
    for m, p, _, op in operations:
        oid = op.get("operationId")
        if not oid:
            missing_opid.append(f"{m.upper()} {p}")
        else:
            opid_map.setdefault(str(oid), []).append(f"{m.upper()} {p}")
    duplicated_opid = {k: v for k, v in opid_map.items() if len(v) > 1}
    print(f"== operationId ausentes: {len(missing_opid)}")
    for s in missing_opid:
        print(f"  - {s}")
    print(f"== operationId duplicados: {len(duplicated_opid)}")
    for k, v in duplicated_opid.items():
        print(f"  - {k}: " + "; ".join(v))
    print()

    # 3. Operaciones sin ninguna respuesta 4xx
    no_4xx = []
    for m, p, _, op in operations:
        codes = [str(c) for c in (op.get("responses") or {})]
        if not any(c.startswith("4") for c in codes):
            no_4xx.append(f"{m.upper()} {p} ({op.get('operationId', '-')})")
    print(f"== operaciones sin respuesta 4xx: {len(no_4xx)}")
    for s in no_4xx:
        print(f"  - {s}")
    print()

    # 4. POST sin Idempotency-Key
    no_idem = []
    post_count = 0
    for m, p, item, op in operations:
        if m != "post":
            continue
        post_count += 1
        params = list(item.get("parameters") or []) + list(op.get("parameters") or [])
        if not any(is_idempotency_param(prm, doc) for prm in params):
            no_idem.append(f"POST {p} ({op.get('operationId', '-')})")
    print(f"== POST sin Idempotency-Key: {len(no_idem)} de {post_count} POST")
    for s in no_idem:
        print(f"  - {s}")
    print()

    # 5. Operaciones públicas (security efectiva vacía)
    public_ops = []
    for m, p, _, op in operations:
        eff = op["security"] if "security" in op else global_security
        if isinstance(eff, list) and len(eff) == 0:
            public_ops.append(f"{m.upper()} {p} ({op.get('operationId', '-')})")
    print(f"== operaciones públicas (security: []): {len(public_ops)}")
    for s in public_ops:
        print(f"  - {s}")
    print()

    # 6. additionalProperties: true alcanzables desde respuestas
    comp_schemas = (doc.get("components") or {}).get("schemas") or {}
    findings = {}  # (ubicación) -> set de operaciones que la alcanzan
    for m, p, _, op in operations:
        label = f"{m.upper()} {p} ({op.get('operationId', '-')})"
        responses = op.get("responses")
        if responses is None:
            continue
        # Inline dentro de responses (sin seguir $ref)
        for sub, node in iter_nodes(responses):
            if isinstance(node, dict) and node.get("additionalProperties") is True:
                loc = f"responses{sub}"
                findings.setdefault(loc, set()).add(label)
        # Schemas de components alcanzados desde esta operación
        for ref in reachable_refs(doc, responses):
            target = resolve(doc, ref)
            if target is MISSING:
                continue
            for sub, node in iter_nodes(target):
                if isinstance(node, dict) and node.get("additionalProperties") is True:
                    loc = f"{ref}{sub}"
                    findings.setdefault(loc, set()).add(label)
    print(f"== additionalProperties: true alcanzables desde respuestas: {len(findings)}")
    for loc in sorted(findings):
        ops = sorted(findings[loc])
        shown = ", ".join(ops[:3]) + (f" (+{len(ops) - 3} más)" if len(ops) > 3 else "")
        print(f"  - {loc}  <- {shown}")
    print()

    # Resumen
    problems = len(broken_refs) + len(missing_opid) + len(duplicated_opid)
    print("== RESUMEN")
    print(f"  refs rotos: {len(broken_refs)}")
    print(f"  operationId ausentes: {len(missing_opid)}, duplicados: {len(duplicated_opid)}")
    print(f"  operaciones sin 4xx: {len(no_4xx)}")
    print(f"  POST sin Idempotency-Key: {len(no_idem)}")
    print(f"  operaciones públicas: {len(public_ops)}")
    print(f"  ubicaciones con additionalProperties: true: {len(findings)}")
    print(f"  resultado: {'FALLO' if problems else 'OK'}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
