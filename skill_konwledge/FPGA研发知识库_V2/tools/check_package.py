"""Read-only package validation; Python 3.10+, standard library only.

Default checks are portable. --verify-sources additionally reads original
source paths to confirm source files were preserved; it is not needed offline.
"""
from pathlib import Path
import argparse
import hashlib
import json
import re
import xml.etree.ElementTree as ET
import zipfile


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check(root, verify_sources=False):
    failures = []
    link_count = 0
    for path in root.rglob('*.md'):
        text = path.read_text(encoding='utf-8-sig')
        text = re.sub(r'(?ms)^(`{3,}|~{3,})[^\n]*\n.*?^\1\s*$', '', text)
        for match in re.finditer(r'\[[^\]\n]*\]\((<[^>]+>|[^\s)]+)\)', text):
            target = match.group(1).strip('<>')
            if re.match(r'^[a-zA-Z]+://', target) or target.startswith('#'):
                continue
            link_count += 1
            if re.match(r'^[A-Za-z]:', target) or target.startswith('/'):
                failures.append('absolute link: '+str(path.relative_to(root))+' -> '+target)
                continue
            dest = (path.parent / target.split('#')[0]).resolve()
            if not dest.is_relative_to(root.resolve()) or not dest.exists():
                failures.append('broken/outside link: '+str(path.relative_to(root))+' -> '+target)

    skills = sorted((root/'skills').glob('*/SKILL.md'))
    lengths = {}
    if len(skills) != 4:
        failures.append('expected four skills')
    for path in skills:
        text = path.read_text(encoding='utf-8')
        parts = text.split('---', 2)
        if len(parts) != 3:
            failures.append('frontmatter: '+path.parent.name)
            continue
        if 'name: '+path.parent.name not in parts[1] or 'description:' not in parts[1]:
            failures.append('metadata: '+path.parent.name)
        body = parts[2]
        # Human-facing body count excludes URL destinations, whitespace and markup.
        visible = re.sub(r'\[([^\]]+)\]\([^)]+\)',r'\1',body)
        lengths[path.parent.name] = len(re.sub(r'\s|[#*`]', '', visible))
        if lengths[path.parent.name] > 650 or '阶段知识入口' not in body or '确认' not in body:
            failures.append('skill length/routing/approval: '+path.parent.name)

    records = json.loads((root/'sources/来源清单.json').read_text(encoding='utf-8'))
    for entry in records:
        path = root/entry['local']
        if not path.is_file() or sha(path) != entry['local_sha256']:
            failures.append('local source mismatch: '+entry['id'])
        if verify_sources:
            original = Path(entry['source'])
            if not original.is_file() or sha(original) != entry['source_sha256']:
                failures.append('original source changed/unavailable: '+entry['id'])

    ns = {'s':'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}
    expected = {
        '设计规格':['编号','模块','功能类别','功能名称','设计要求','备注'],
        '测试点':['编号','类别','子类别','测试点内容','对应验证用例名称','设计规格反标'],
        '测试用例':['编号','名称','验证层级','测试点反标','准备与输入','预期结果','执行结果']}
    templates = sorted((root/'templates').glob('*'))
    if len(templates)!=4:
        failures.append('expected 4 templates')
    for path in templates:
        with zipfile.ZipFile(path) as z:
            if z.testzip():
                failures.append('zip CRC: '+path.name)
            for name in z.namelist():
                if name.endswith(('.xml','.rels')):
                    ET.fromstring(z.read(name))
            if path.suffix=='.xlsx':
                book=ET.fromstring(z.read('xl/workbook.xml'))
                sheets=[x.attrib['name'] for x in book.findall('s:sheets/s:sheet',ns)]
                if sheets!=list(expected):
                    failures.append('sheet names')
                styles=ET.fromstring(z.read('xl/styles.xml'))
                fonts=styles.find('s:fonts',ns)
                xfs=styles.find('s:cellXfs',ns)
                for i,sheet in enumerate(sheets,1):
                    tree=ET.fromstring(z.read(f'xl/worksheets/sheet{i}.xml'))
                    cells=tree.findall("s:sheetData/s:row[@r='1']/s:c",ns)
                    headers=[''.join(c.itertext()) for c in cells]
                    if headers!=expected[sheet]:
                        failures.append('headers: '+sheet)
                    for row in tree.findall('s:sheetData/s:row',ns):
                        is_header=row.attrib['r']=='1'
                        for cell in row.findall('s:c',ns):
                            xf=xfs[int(cell.attrib.get('s','0'))]
                            font=fonts[int(xf.attrib['fontId'])]
                            if font.find('s:name',ns).attrib['val'] not in ('微软雅黑','Microsoft YaHei') or float(font.find('s:sz',ns).attrib['val'])!=(13 if is_header else 12):
                                failures.append('font: '+sheet+' '+cell.attrib['r'])
                            if xf.find('s:alignment',ns).attrib.get('wrapText')!='1':
                                failures.append('wrap: '+sheet)
                    pane=tree.find('s:sheetViews/s:sheetView/s:pane',ns)
                    if pane is None or pane.attrib.get('topLeftCell')!='A2':
                        failures.append('freeze: '+sheet)

    filelist=root/'examples/sv_uvm_minimal/filelist.f'
    for line in filelist.read_text(encoding='utf-8').splitlines():
        line=line.strip()
        if line and not line.startswith(('+','#','//')) and not (filelist.parent/line).is_file():
            failures.append('filelist missing '+line)
    forbidden=[p for p in root.rglob('*') if p.suffix.lower() in ('.pdf','.png','.jpg','.wdb','.vcd')]
    if forbidden:
        failures.append('unexpected PDF/media/waveform files')
    return {'passed':not failures,'links_checked':link_count,'skills':lengths,'source_records':len(records),'templates':len(templates),'failures':failures}


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[1])
    parser.add_argument('--verify-sources',action='store_true')
    args=parser.parse_args()
    result=check(args.root,args.verify_sources)
    print(json.dumps(result,ensure_ascii=False,indent=2))
    raise SystemExit(0 if result['passed'] else 1)
