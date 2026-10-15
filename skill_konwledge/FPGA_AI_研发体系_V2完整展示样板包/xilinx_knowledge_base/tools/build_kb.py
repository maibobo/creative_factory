#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import fnmatch
import hashlib
import html
import json
import os
import re
import shutil
import sqlite3
import subprocess
import tempfile
import unicodedata
import zipfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Iterable


CODE_LANG = {
    ".v": "verilog", ".vh": "verilog", ".sv": "systemverilog", ".svh": "systemverilog",
    ".vhd": "vhdl", ".vhdl": "vhdl", ".xdc": "tcl", ".tcl": "tcl", ".xci": "xml",
    ".prj": "tcl", ".f": "text", ".mk": "makefile", ".ps1": "powershell", ".py": "python",
    ".c": "c", ".h": "c", ".cpp": "cpp", ".hpp": "cpp", ".sh": "bash",
}


@dataclass
class Candidate:
    path: Path
    category: str
    priority: int
    tags: set[str] = field(default_factory=set)
    max_size_mb: int = 80


@dataclass
class Extracted:
    candidate: Candidate
    sha256: str
    text: str
    extractor: str
    aliases: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build the local Xilinx knowledge base")
    parser.add_argument("--config", required=True)
    parser.add_argument("--clean", action="store_true")
    parser.add_argument("--verbose", action="store_true")
    return parser.parse_args()


def normalized_path(path: Path | str) -> str:
    return str(path).replace("\\", "/").lower()


def read_config(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def is_excluded_dir(name: str, config: dict) -> bool:
    lowered = name.lower()
    if lowered in {item.lower() for item in config["excluded_directory_names"]}:
        return True
    if any(lowered.startswith(prefix.lower()) for prefix in config.get("excluded_directory_prefixes", [])):
        return True
    return any(lowered.endswith(suffix.lower()) for suffix in config["excluded_directory_suffixes"])


def path_has_excluded_term(path: Path | str, config: dict, extra_terms: Iterable[str] = ()) -> bool:
    text = normalized_path(path)
    terms = list(config.get("excluded_path_terms", [])) + list(extra_terms)
    return any(term.lower() in text for term in terms)


def add_candidate(store: dict[str, Candidate], candidate: Candidate) -> None:
    key = os.path.normcase(os.path.abspath(candidate.path))
    previous = store.get(key)
    if previous is None or candidate.priority > previous.priority:
        if previous:
            candidate.tags.update(previous.tags)
        store[key] = candidate
    else:
        previous.tags.update(candidate.tags)


def collect_candidates(config: dict, report: dict) -> list[Candidate]:
    allowed = {item.lower() for item in config["allowed_extensions"]}
    store: dict[str, Candidate] = {}

    for item in config.get("explicit_files", []):
        path = Path(item["path"])
        if not path.is_file():
            report["missing_sources"].append(str(path))
            continue
        if path.name.startswith("~$"):
            continue
        add_candidate(store, Candidate(path, item["category"], int(item.get("priority", 50)), set(item.get("tags", [])), int(item.get("max_size_mb", 200))))

    for source in config.get("sources", []):
        root = Path(source["path"])
        if not root.exists():
            report["missing_sources"].append(str(root))
            continue
        category = source["category"]
        priority = int(source.get("priority", 50))
        tags = set(source.get("tags", []))
        max_size_mb = int(source.get("max_size_mb", 80))
        extra_terms = source.get("exclude_path_terms", [])
        include_patterns = source.get("include_patterns", [])

        if root.is_file():
            paths = [root]
        else:
            paths = []
            for current, dirs, files in os.walk(root):
                dirs[:] = [
                    name for name in dirs
                    if not is_excluded_dir(name, config)
                    and not path_has_excluded_term(Path(current) / name, config, extra_terms)
                ]
                for name in files:
                    paths.append(Path(current) / name)

        for path in paths:
            if path.name.startswith("~$") or path.suffix.lower() not in allowed:
                continue
            if path_has_excluded_term(path, config, extra_terms):
                continue
            if include_patterns:
                rel = normalized_path(path.relative_to(root) if root.is_dir() else path.name)
                if not any(fnmatch.fnmatch(rel, pattern.lower()) for pattern in include_patterns):
                    continue
            try:
                size = path.stat().st_size
            except OSError as exc:
                report["errors"].append({"path": str(path), "error": str(exc)})
                continue
            if size > max_size_mb * 1024 * 1024:
                report["skipped_large"].append({"path": str(path), "size": size})
                continue
            add_candidate(store, Candidate(path, category, priority, set(tags), max_size_mb))

    return sorted(store.values(), key=lambda item: (-item.priority, normalized_path(item.path)))


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_text_file(path: Path) -> str:
    data = path.read_bytes()
    if b"\x00" in data[:4096] and path.suffix.lower() not in {".xci"}:
        raise ValueError("binary-looking text file")
    for encoding in ("utf-8-sig", "utf-8", "gb18030", "cp1252"):
        try:
            return data.decode(encoding)
        except UnicodeDecodeError:
            pass
    return data.decode("utf-8", errors="replace")


def extract_html(path: Path) -> str:
    text = read_text_file(path)
    text = re.sub(r"(?is)<(script|style).*?>.*?</\1>", " ", text)
    text = re.sub(r"(?s)<[^>]+>", " ", text)
    return html.unescape(text)


def extract_pdf(path: Path) -> tuple[str, str]:
    from pypdf import PdfReader

    reader = PdfReader(str(path), strict=False)
    if reader.is_encrypted:
        try:
            reader.decrypt("")
        except Exception as exc:
            raise ValueError(f"encrypted PDF: {exc}") from exc
    parts = []
    for number, page in enumerate(reader.pages, 1):
        try:
            text = page.extract_text() or ""
        except Exception as exc:
            text = f"[page extraction error: {exc}]"
        if text.strip():
            parts.append(f"## Page {number}\n\n{text.strip()}")
    return "\n\n".join(parts), f"pypdf:{len(reader.pages)}pages"


def iter_docx_blocks(document):
    from docx.document import Document as DocumentType
    from docx.table import Table
    from docx.text.paragraph import Paragraph

    parent = document.element.body if isinstance(document, DocumentType) else document._tc
    for child in parent.iterchildren():
        if child.tag.endswith("}p"):
            yield Paragraph(child, document)
        elif child.tag.endswith("}tbl"):
            yield Table(child, document)


def extract_docx(path: Path) -> tuple[str, str]:
    from docx import Document
    from docx.table import Table

    with zipfile.ZipFile(path) as archive:
        bad = archive.testzip()
        required = {"[Content_Types].xml", "word/document.xml"}
        missing = required.difference(archive.namelist())
        if bad or missing:
            raise ValueError(f"DOCX structure error bad={bad!r} missing={sorted(missing)}")

    document = Document(str(path))
    lines: list[str] = []
    for block in iter_docx_blocks(document):
        if isinstance(block, Table):
            for row in block.rows:
                cells = [re.sub(r"\s+", " ", cell.text).strip().replace("|", "\\|") for cell in row.cells]
                if any(cells):
                    lines.append("| " + " | ".join(cells) + " |")
            lines.append("")
        else:
            text = block.text.strip()
            if not text:
                continue
            style = (block.style.name or "") if block.style else ""
            match = re.match(r"Heading\s+(\d+)", style, re.I)
            if match:
                level = min(6, int(match.group(1)))
                lines.append(f"{'#' * level} {text}")
            else:
                lines.append(text)
    return "\n\n".join(lines), "python-docx+zip-structure-check"


def extract_doc(path: Path, soffice: Path) -> tuple[str, str]:
    if not soffice.is_file():
        raise FileNotFoundError(f"LibreOffice not found at required path: {soffice}")
    with tempfile.TemporaryDirectory(prefix="xilinx_kb_doc_") as temp_dir:
        temp = Path(temp_dir)
        out_dir = temp / "out"
        profile = temp / "profile"
        out_dir.mkdir()
        profile.mkdir()
        command = [
            str(soffice), f"-env:UserInstallation={profile.as_uri()}", "--headless",
            "--convert-to", "txt:Text (encoded):UTF8", "--outdir", str(out_dir), str(path),
        ]
        completed = subprocess.run(command, capture_output=True, text=True, timeout=180, check=False)
        outputs = list(out_dir.glob("*.txt"))
        if completed.returncode != 0 or not outputs:
            detail = (completed.stdout + "\n" + completed.stderr).strip()
            raise RuntimeError(f"LibreOffice DOC extraction failed: {detail}")
        return read_text_file(outputs[0]), "libreoffice-text"


def encrypted_ooxml_placeholder(path: Path) -> tuple[str, str] | None:
    """Identify password-protected OOXML stored in an OLE compound container.

    Encrypted DOCX files are not ZIP archives.  Their OLE directory contains
    EncryptionInfo and EncryptedPackage streams, so sending them through the
    legacy-DOC converter produces a misleading conversion error.
    """
    with path.open("rb") as stream:
        magic = stream.read(8)
        if magic != bytes.fromhex("D0CF11E0A1B11AE1"):
            return None
        stream.seek(0)
        payload = stream.read()
    required = ("EncryptionInfo".encode("utf-16le"), "EncryptedPackage".encode("utf-16le"))
    if not all(name in payload for name in required):
        return None
    text = (
        "# 加密 Office 文档占位\n\n"
        "该文件是存放在 OLE 容器中的密码保护 OOXML 文档。当前知识库没有文档密码，"
        "因此未提取正文，也不把它作为技术结论证据。文件路径、哈希和重复来源仍保留，"
        "便于获得密码或未加密副本后增量重建。"
    )
    return text, "encrypted-ooxml-placeholder"


def xlsx_ndjson_to_text(ndjson: str) -> str:
    lines: list[str] = []
    current_sheet = None
    for raw in ndjson.splitlines():
        if not raw.strip():
            continue
        record = json.loads(raw)
        kind = record.get("kind")
        if kind == "workbook":
            lines.append(f"# Workbook ({record.get('sheets', 0)} sheets)")
        elif kind == "sheet":
            current_sheet = record.get("name", "Sheet")
            lines.append(f"\n## Sheet: {current_sheet}\n")
        elif kind == "table":
            sheet = record.get("sheet") or current_sheet or "Sheet"
            lines.append(f"### Range: {sheet}!{record.get('address', '')}")
            for row in record.get("values", []):
                values = []
                for value in row:
                    text = "" if value is None else str(value)
                    values.append(re.sub(r"\s+", " ", text).strip().replace("|", "\\|"))
                lines.append("| " + " | ".join(values) + " |")
            lines.append("")
        elif kind == "notice":
            lines.append(f"[Workbook notice: {record.get('message', '')}]")
    return "\n".join(lines)


def extract_xlsx(path: Path, node_exe: Path, script: Path) -> tuple[str, str]:
    if not node_exe.is_file():
        raise FileNotFoundError(f"Node.js not found: {node_exe}")
    with tempfile.TemporaryDirectory(prefix="xilinx_kb_xlsx_") as temp_dir:
        output = Path(temp_dir) / "workbook.ndjson"
        completed = subprocess.run(
            [str(node_exe), str(script), str(path), str(output)],
            capture_output=True, text=True, timeout=300, check=False,
        )
        if completed.returncode != 0 or not output.is_file():
            detail = (completed.stdout + "\n" + completed.stderr).strip()
            raise RuntimeError(f"artifact-tool XLSX extraction failed: {detail}")
        return xlsx_ndjson_to_text(output.read_text(encoding="utf-8")), "artifact-tool"


def normalize_text(text: str) -> str:
    text = unicodedata.normalize("NFC", text.replace("\x00", ""))
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = re.sub(r"[ \t]+\n", "\n", text)
    text = re.sub(r"\n{4,}", "\n\n\n", text)
    return text.strip()


def extract_candidate(candidate: Candidate, config: dict, kb_root: Path) -> tuple[str, str]:
    path = candidate.path
    suffix = path.suffix.lower()
    if suffix == ".pdf":
        return extract_pdf(path)
    if suffix == ".docx":
        try:
            return extract_docx(path)
        except zipfile.BadZipFile:
            encrypted = encrypted_ooxml_placeholder(path)
            if encrypted:
                return encrypted
            with tempfile.TemporaryDirectory(prefix="xilinx_kb_misnamed_docx_") as temp_dir:
                legacy_copy = Path(temp_dir) / f"{path.stem}.doc"
                shutil.copyfile(path, legacy_copy)
                text, _ = extract_doc(legacy_copy, Path(config["extractors"]["soffice"]))
            return text, "libreoffice-text-misnamed-docx"
    if suffix == ".doc":
        return extract_doc(path, Path(config["extractors"]["soffice"]))
    if suffix == ".xlsx":
        return extract_xlsx(path, Path(config["extractors"]["node_exe"]), kb_root / "tools" / "extract_xlsx.mjs")
    if suffix in {".html", ".htm"}:
        return extract_html(path), "html-strip"
    return read_text_file(path), "text"


def slugify(text: str) -> str:
    text = unicodedata.normalize("NFC", text)
    text = re.sub(r"[^\w.-]+", "_", text, flags=re.UNICODE).strip("_.")
    return (text or "document")[:100]


def markdown_for(extracted: Extracted) -> str:
    path = extracted.candidate.path
    aliases = "\n".join(f"  - {item}" for item in extracted.aliases) or "  - none"
    tags = ", ".join(sorted(extracted.candidate.tags))
    header = (
        f"# {path.stem}\n\n"
        f"- Category: `{extracted.candidate.category}`\n"
        f"- Source: `{path}`\n"
        f"- SHA-256: `{extracted.sha256}`\n"
        f"- Extractor: `{extracted.extractor}`\n"
        f"- Tags: `{tags}`\n"
        f"- Duplicate sources:\n{aliases}\n\n"
    )
    suffix = path.suffix.lower()
    if suffix in CODE_LANG:
        language = CODE_LANG[suffix]
        return header + f"```{language}\n{extracted.text}\n```\n"
    return header + extracted.text + "\n"


def chunk_text(text: str, target: int = 3200, overlap: int = 300) -> list[str]:
    paragraphs = re.split(r"\n\s*\n", text)
    chunks: list[str] = []
    current = ""
    for paragraph in paragraphs:
        paragraph = paragraph.strip()
        if not paragraph:
            continue
        if len(paragraph) > target:
            if current:
                chunks.append(current)
                current = ""
            start = 0
            while start < len(paragraph):
                end = min(len(paragraph), start + target)
                chunks.append(paragraph[start:end])
                if end == len(paragraph):
                    break
                start = max(start + 1, end - overlap)
            continue
        proposed = paragraph if not current else current + "\n\n" + paragraph
        if len(proposed) > target and current:
            chunks.append(current)
            prefix = current[-overlap:] if overlap else ""
            current = (prefix + "\n\n" + paragraph).strip()
        else:
            current = proposed
    if current:
        chunks.append(current)
    return chunks


def corpus_body(corpus_path: Path, kind: str) -> str | None:
    try:
        content = corpus_path.read_text(encoding="utf-8")
    except OSError:
        return None
    match = re.search(r"\n- Duplicate sources:\n(?:  - .*\n)+\n", content)
    if not match:
        return None
    body = content[match.end():].strip()
    if ("." + kind.lower()) in CODE_LANG and body.startswith("```"):
        first_newline = body.find("\n")
        if first_newline >= 0:
            body = body[first_newline + 1:]
        if body.endswith("```"):
            body = body[:-3].rstrip()
    return body or None


def prime_cache_from_manifest(kb_root: Path, cache_root: Path) -> int:
    manifest_path = kb_root / "index" / "manifest.json"
    if not manifest_path.is_file():
        return 0
    try:
        entries = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return 0
    cache_root.mkdir(parents=True, exist_ok=True)
    count = 0
    for entry in entries:
        digest = entry.get("sha256")
        if not digest:
            continue
        text_path = cache_root / f"{digest}.txt"
        meta_path = cache_root / f"{digest}.json"
        if text_path.is_file() and meta_path.is_file():
            continue
        body = corpus_body(Path(entry.get("corpus_path", "")), entry.get("kind", ""))
        if not body:
            continue
        text_path.write_text(body, encoding="utf-8", newline="\n")
        meta_path.write_text(json.dumps({"extractor": entry.get("extractor", "cache")}, ensure_ascii=False), encoding="utf-8")
        count += 1
    return count


def read_cache(cache_root: Path, digest: str) -> tuple[str, str] | None:
    text_path = cache_root / f"{digest}.txt"
    meta_path = cache_root / f"{digest}.json"
    if not text_path.is_file():
        return None
    try:
        text = text_path.read_text(encoding="utf-8")
        extractor = "cache"
        if meta_path.is_file():
            extractor = json.loads(meta_path.read_text(encoding="utf-8")).get("extractor", "cache")
        return text, extractor
    except (OSError, json.JSONDecodeError):
        return None


def write_cache(cache_root: Path, digest: str, text: str, extractor: str) -> None:
    cache_root.mkdir(parents=True, exist_ok=True)
    (cache_root / f"{digest}.txt").write_text(text, encoding="utf-8", newline="\n")
    (cache_root / f"{digest}.json").write_text(json.dumps({"extractor": extractor}, ensure_ascii=False), encoding="utf-8")


def prune_cache(cache_root: Path, keep_hashes: set[str]) -> None:
    if not cache_root.is_dir():
        return
    for path in cache_root.iterdir():
        if path.is_file() and path.suffix in {".txt", ".json"} and path.stem not in keep_hashes:
            path.unlink()


def initialize_database(path: Path) -> tuple[sqlite3.Connection, bool]:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()
    conn = sqlite3.connect(path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("CREATE TABLE documents (id TEXT PRIMARY KEY, title TEXT, category TEXT, kind TEXT, source_path TEXT, aliases_json TEXT, sha256 TEXT, modified_at TEXT, size_bytes INTEGER, extractor TEXT, chars INTEGER, corpus_path TEXT, tags TEXT)")
    conn.execute("CREATE TABLE chunks (id INTEGER PRIMARY KEY, doc_id TEXT, ordinal INTEGER, text TEXT, FOREIGN KEY(doc_id) REFERENCES documents(id))")
    conn.execute("CREATE VIRTUAL TABLE chunks_fts USING fts5(doc_id UNINDEXED, category UNINDEXED, title, source_path, text, tokenize='unicode61 remove_diacritics 2')")
    trigram = True
    try:
        conn.execute("CREATE VIRTUAL TABLE chunks_trigram USING fts5(doc_id UNINDEXED, category UNINDEXED, title, source_path, text, tokenize='trigram')")
    except sqlite3.OperationalError:
        trigram = False
        conn.execute("CREATE VIEW chunks_trigram AS SELECT d.id AS doc_id, d.category, d.title, d.source_path, c.text FROM chunks c JOIN documents d ON d.id=c.doc_id")
    return conn, trigram


def write_manifest(kb_root: Path, documents: list[dict]) -> None:
    index_dir = kb_root / "index"
    index_dir.mkdir(parents=True, exist_ok=True)
    (index_dir / "manifest.json").write_text(json.dumps(documents, ensure_ascii=False, indent=2), encoding="utf-8")
    fields = ["id", "title", "category", "kind", "source_path", "sha256", "modified_at", "size_bytes", "extractor", "chars", "corpus_path", "tags", "aliases"]
    with (index_dir / "manifest.csv").open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for doc in documents:
            row = dict(doc)
            row["tags"] = ";".join(doc["tags"])
            row["aliases"] = ";".join(doc["aliases"])
            writer.writerow(row)


def main() -> int:
    args = parse_args()
    config_path = Path(args.config).resolve()
    kb_root = config_path.parent.parent
    config = read_config(config_path)
    report = {
        "started_at": datetime.now().astimezone().isoformat(),
        "missing_sources": [], "skipped_large": [], "errors": [], "duplicates": [],
    }
    candidates = collect_candidates(config, report)
    if args.verbose:
        print(f"candidates={len(candidates)}")

    corpus_root = kb_root / "corpus"
    cache_root = kb_root / "cache" / "extracted"
    primed = prime_cache_from_manifest(kb_root, cache_root)
    report["cache_primed"] = primed
    if args.clean and corpus_root.exists():
        shutil.rmtree(corpus_root)
    corpus_root.mkdir(parents=True, exist_ok=True)

    extracted_by_hash: dict[str, Extracted] = {}
    for number, candidate in enumerate(candidates, 1):
        try:
            digest = sha256_file(candidate.path)
            previous = extracted_by_hash.get(digest)
            if previous:
                previous.aliases.append(str(candidate.path))
                previous.candidate.tags.update(candidate.tags)
                report["duplicates"].append({"canonical": str(previous.candidate.path), "duplicate": str(candidate.path), "sha256": digest})
                continue
            cached = read_cache(cache_root, digest)
            if cached:
                text, extractor = cached
            else:
                text, extractor = extract_candidate(candidate, config, kb_root)
                text = normalize_text(text)
                write_cache(cache_root, digest, text, extractor)
            if len(text) < 20:
                raise ValueError("extracted text is empty or too short")
            extracted_by_hash[digest] = Extracted(candidate, digest, text, extractor)
            if args.verbose:
                print(f"[{number}/{len(candidates)}] {candidate.category}: {candidate.path}")
        except Exception as exc:
            report["errors"].append({"path": str(candidate.path), "error": f"{type(exc).__name__}: {exc}"})
            if args.verbose:
                print(f"ERROR {candidate.path}: {exc}")

    db_path = kb_root / "index" / "xilinx_kb.sqlite3"
    conn, trigram = initialize_database(db_path)
    documents: list[dict] = []
    for item in sorted(extracted_by_hash.values(), key=lambda value: (value.candidate.category, normalized_path(value.candidate.path))):
        candidate = item.candidate
        doc_id = item.sha256[:16]
        title = candidate.path.stem
        category_dir = corpus_root / candidate.category
        category_dir.mkdir(parents=True, exist_ok=True)
        corpus_path = category_dir / f"{slugify(title)}-{doc_id}.md"
        corpus_path.write_text(markdown_for(item), encoding="utf-8", newline="\n")
        stat = candidate.path.stat()
        metadata = {
            "id": doc_id,
            "title": title,
            "category": candidate.category,
            "kind": candidate.path.suffix.lower().lstrip("."),
            "source_path": str(candidate.path),
            "aliases": sorted(set(item.aliases)),
            "sha256": item.sha256,
            "modified_at": datetime.fromtimestamp(stat.st_mtime).astimezone().isoformat(),
            "size_bytes": stat.st_size,
            "extractor": item.extractor,
            "chars": len(item.text),
            "corpus_path": str(corpus_path),
            "tags": sorted(candidate.tags),
        }
        documents.append(metadata)
        conn.execute(
            "INSERT INTO documents VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (doc_id, title, candidate.category, metadata["kind"], str(candidate.path), json.dumps(metadata["aliases"], ensure_ascii=False), item.sha256, metadata["modified_at"], stat.st_size, item.extractor, len(item.text), str(corpus_path), json.dumps(metadata["tags"], ensure_ascii=False)),
        )
        for ordinal, chunk in enumerate(chunk_text(item.text)):
            conn.execute("INSERT INTO chunks(doc_id, ordinal, text) VALUES (?,?,?)", (doc_id, ordinal, chunk))
            conn.execute("INSERT INTO chunks_fts(doc_id, category, title, source_path, text) VALUES (?,?,?,?,?)", (doc_id, candidate.category, title, str(candidate.path), chunk))
            if trigram:
                conn.execute("INSERT INTO chunks_trigram(doc_id, category, title, source_path, text) VALUES (?,?,?,?,?)", (doc_id, candidate.category, title, str(candidate.path), chunk))
    conn.commit()
    conn.execute("PRAGMA optimize")
    conn.close()

    if args.clean:
        prune_cache(cache_root, set(extracted_by_hash))

    write_manifest(kb_root, documents)
    report["finished_at"] = datetime.now().astimezone().isoformat()
    report["candidate_count"] = len(candidates)
    report["document_count"] = len(documents)
    report["character_count"] = sum(doc["chars"] for doc in documents)
    report["trigram_index"] = trigram
    report_path = kb_root / "index" / "build_report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    with (kb_root / "index" / "excluded.jsonl").open("w", encoding="utf-8") as handle:
        for kind in ("missing_sources", "skipped_large", "errors"):
            for item in report[kind]:
                handle.write(json.dumps({"kind": kind, "detail": item}, ensure_ascii=False) + "\n")

    print(f"documents={report['document_count']} chars={report['character_count']} candidates={report['candidate_count']}")
    print(f"duplicates={len(report['duplicates'])} errors={len(report['errors'])} missing_sources={len(report['missing_sources'])}")
    print(f"index={db_path}")
    return 0 if documents else 1


if __name__ == "__main__":
    raise SystemExit(main())
