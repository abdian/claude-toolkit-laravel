#!/usr/bin/env python3
"""docx -> markdown, با کتابخانه استاندارد پایتون. بدون نصب چیزی.

    python3 docx2md.py سند-من.docx > /tmp/brain-dump.md

عنوان‌ها، پاراگراف، لیست و جدول رو نگه می‌داره — جدول مهم‌ترینه، چون
GLOSSARY و PERMISSIONS و PANELS همه جدولن.
"""
import re, sys, zipfile
import xml.etree.ElementTree as ET

W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'


def text_of(el):
    """متن یک پاراگراف، با احترام به tab و line-break."""
    out = []
    for node in el.iter():
        tag = node.tag
        if tag == W + 't':
            out.append(node.text or '')
        elif tag == W + 'tab':
            out.append('\t')
        elif tag in (W + 'br', W + 'cr'):
            out.append('\n')
    return ''.join(out).strip()


def style_of(p):
    s = p.find(f'{W}pPr/{W}pStyle')
    return (s.get(W + 'val') or '') if s is not None else ''


def is_list(p):
    return p.find(f'{W}pPr/{W}numPr') is not None or 'ListParagraph' in style_of(p)


def heading_level(p):
    """سطح عنوان از روی استایل. ورد اسم‌های مختلفی می‌دهد:
    Heading1 / Heading 1 / heading 1 / Titre1 (نسخه‌های محلی‌شده)."""
    st = style_of(p).strip()
    low = st.lower().replace(' ', '')
    if low in ('title', 'subtitle'):
        return 1 if low == 'title' else 2
    m = re.match(r'^(?:heading|h|titre|berschrift)(\d)$', low)
    if m:
        return min(int(m.group(1)), 6)
    return 0


def table_to_md(tbl):
    rows = []
    for tr in tbl.findall(f'{W}tr'):
        cells = [text_of(tc).replace('\n', ' ').replace('|', r'\|')
                 for tc in tr.findall(f'{W}tc')]
        if cells:
            rows.append(cells)
    if not rows:
        return ''
    width = max(len(r) for r in rows)
    rows = [r + [''] * (width - len(r)) for r in rows]
    head, body = rows[0], rows[1:]
    out = ['| ' + ' | '.join(head) + ' |',
           '|' + '|'.join(['---'] * width) + '|']
    out += ['| ' + ' | '.join(r) + ' |' for r in body]
    return '\n'.join(out)


def convert(path):
    with zipfile.ZipFile(path) as z:
        try:
            xml = z.read('word/document.xml')
        except KeyError:
            sys.exit('این فایل docx معتبر نیست (word/document.xml ندارد).')
    body = ET.fromstring(xml).find(f'{W}body')
    if body is None:
        sys.exit('بدنه سند پیدا نشد.')

    out, blank = [], False
    for child in body:
        if child.tag == W + 'tbl':
            md = table_to_md(child)
            if md:
                out += ['', md, '']
                blank = True
            continue
        if child.tag != W + 'p':
            continue
        t = text_of(child)
        if not t:
            if not blank:
                out.append('')
                blank = True
            continue
        blank = False
        lvl = heading_level(child)
        if lvl:
            out += ['', '#' * lvl + ' ' + t, '']
            blank = True
        elif is_list(child):
            out.append('- ' + t)
        else:
            out.append(t)

    md = '\n'.join(out)
    return re.sub(r'\n{3,}', '\n\n', md).strip() + '\n'


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stdout.write(convert(sys.argv[1]))
