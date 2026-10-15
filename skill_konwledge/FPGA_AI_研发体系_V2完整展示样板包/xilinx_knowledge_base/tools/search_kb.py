#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Search the local Xilinx knowledge base")
    parser.add_argument("query", nargs="?", help="search text")
    parser.add_argument("--db", required=True, help="path to SQLite index")
    parser.add_argument("--category", help="foundation/aurora/pcie/ddr/ethernet/cross_ip/guide")
    parser.add_argument("--limit", type=int, default=10)
    parser.add_argument("--stats", action="store_true")
    parser.add_argument("--json", action="store_true", dest="as_json")
    return parser.parse_args()


def stats(conn: sqlite3.Connection) -> list[dict]:
    rows = conn.execute(
        "SELECT category, COUNT(*) AS documents, SUM(chars) AS chars "
        "FROM documents GROUP BY category ORDER BY category"
    ).fetchall()
    return [dict(row) for row in rows]


def query_tokens(query: str) -> list[str]:
    tokens = re.findall(r"[\w.+:/-]+", query, flags=re.UNICODE)
    return [token for token in tokens if token]


def fts_expression(tokens: list[str], joiner: str) -> str:
    usable = [token for token in tokens if len(token) >= 3]
    return joiner.join('"' + token.replace('"', '""') + '"' for token in usable)


def run_trigram(conn: sqlite3.Connection, expression: str, category: str | None, limit: int):
    if not expression:
        return []
    params: list[object] = [expression]
    where = "WHERE chunks_trigram MATCH ?"
    if category:
        where += " AND category = ?"
        params.append(category)
    params.append(limit)
    sql = (
        "SELECT doc_id, category, title, source_path, "
        "snippet(chunks_trigram, 4, '[', ']', ' … ', 24) AS snippet, "
        "bm25(chunks_trigram) AS score "
        f"FROM chunks_trigram {where} ORDER BY score LIMIT ?"
    )
    try:
        return conn.execute(sql, params).fetchall()
    except sqlite3.OperationalError:
        return []


def search(conn: sqlite3.Connection, query: str, category: str | None, limit: int) -> list[dict]:
    tokens = query_tokens(query)
    rows = run_trigram(conn, fts_expression(tokens, " AND "), category, limit)
    if not rows and len(tokens) > 1:
        rows = run_trigram(conn, fts_expression(tokens, " OR "), category, limit)

    if not rows:
        likes = [f"%{token}%" for token in tokens] or [f"%{query}%"]
        where = "WHERE (" + " OR ".join("c.text LIKE ?" for _ in likes) + ")"
        params: list[object] = list(likes)
        if category:
            where += " AND d.category = ?"
            params.append(category)
        params.append(limit)
        marker = tokens[0] if tokens else query
        rows = conn.execute(
            "SELECT d.id AS doc_id, d.category, d.title, d.source_path, "
            "substr(c.text, max(1, instr(lower(c.text), lower(?)) - 100), 500) AS snippet, 0 AS score "
            "FROM chunks c JOIN documents d ON d.id = c.doc_id " + where + " LIMIT ?",
            [marker, *params],
        ).fetchall()

    results = []
    for row in rows:
        item = dict(row)
        doc = conn.execute(
            "SELECT corpus_path, aliases_json, tags FROM documents WHERE id = ?", (item["doc_id"],)
        ).fetchone()
        item["corpus_path"] = doc["corpus_path"]
        item["aliases"] = json.loads(doc["aliases_json"] or "[]")
        item["tags"] = json.loads(doc["tags"] or "[]")
        results.append(item)
    return results


def main() -> int:
    args = parse_args()
    db_path = Path(args.db)
    if not db_path.exists():
        print(f"Index not found: {db_path}\nRun build.ps1 first.", file=sys.stderr)
        return 2
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    if args.stats:
        rows = stats(conn)
        if args.as_json:
            print(json.dumps(rows, ensure_ascii=False, indent=2))
        else:
            total_docs = sum(row["documents"] for row in rows)
            total_chars = sum(row["chars"] or 0 for row in rows)
            print(f"documents={total_docs} chars={total_chars}")
            for row in rows:
                print(f"{row['category']:12} documents={row['documents']:4} chars={row['chars'] or 0}")
        return 0

    if not args.query:
        print("Provide a query or use --stats.", file=sys.stderr)
        return 2
    rows = search(conn, args.query, args.category, max(1, args.limit))
    if args.as_json:
        print(json.dumps(rows, ensure_ascii=False, indent=2))
    else:
        if not rows:
            print("No matches.")
        for index, row in enumerate(rows, 1):
            print(f"[{index}] {row['title']}  ({row['category']})")
            print(f"    source: {row['source_path']}")
            print(f"    corpus: {row['corpus_path']}")
            print(f"    {row['snippet'].replace(chr(10), ' ')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
