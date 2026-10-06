"""風語輸入法 — 產生詞庫 rime/fengyu.dict.yaml。

用法：python gen_dict.py
內容：
  1. 教育部《重編國語辭典修訂本》所有字詞的所有讀音（破音字、又音、語音、讀音）
     資料：tools/dict-revised.json.xz（g0v moedict-data；辭典本文著作權屬教育部，CC BY-ND 3.0 TW）
  2. 「一」「不」變調讀音（ㄧˊ ㄧㄤˋ → 一樣）
  3. 其餘沿用 terra_pinyin（import_tables）
"""
import json
import lzma
import re
from pathlib import Path

from gen_english import PINYIN_TO_ZHUYIN, RIME_DATA
from gen_sandhi import char_readings, sandhi

HERE = Path(__file__).resolve().parent
OUT = HERE.parent / 'rime' / 'fengyu.dict.yaml'
MOE = HERE / 'dict-revised.json.xz'

HEADER = """# 風語輸入法（AIW 風光Ai窗）— 詞庫
# 由 tools/gen_dict.py 產生，請勿手動修改
# 讀音資料：教育部《重編國語辭典修訂本》（CC BY-ND 3.0 TW）；新酷音詞庫 libchewing-data（LGPL-2.1）
---
name: fengyu
version: "1.0.0"
sort: by_weight
use_preset_vocabulary: true
import_tables:
  - terra_pinyin
...
"""

INTERNAL = 'bpmfdtnlgkhjqxZCSrzcsiuvaoeEAIOUMNKGR'
ZHUYIN = 'ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦ'
TONES = {'ˊ': '2', 'ˇ': '3', 'ˋ': '4', '˙': '5'}
CJK = re.compile(r'^[㐀-鿿\U00020000-\U0002ffff]+$')


def zhuyin_to_pinyin_table():
    """注音（不含聲調）→ terra_pinyin 拼音（不含聲調），由 terra_pinyin 的所有音節反推"""
    body = (RIME_DATA / 'terra_pinyin.dict.yaml').read_text(encoding='utf-8').split('\n...\n', 1)[1]
    table = {}
    for line in body.splitlines():
        parts = line.split('\t')
        if len(parts) < 2 or line.startswith('#'):
            continue
        for p in parts[1].split(' '):
            if not p or not p[-1].isdigit():
                continue
            base = p[:-1]
            s = p
            for pat, rep in PINYIN_TO_ZHUYIN:
                s = re.sub(pat, rep, s)
            zy = s[:-1].translate(str.maketrans(INTERNAL, ZHUYIN))
            table.setdefault(zy, base)
    # terra_pinyin 沒有、教育部辭典有的音節（這 ㄓㄟˋ、塞 ㄙㄟ）
    table.setdefault('ㄓㄟ', 'zhei')
    table.setdefault('ㄙㄟ', 'sei')
    return table


def split_erhua(word, syls):
    """兒化音：辭典把「兒」併入前一音節（一會兒 ㄏㄨㄟˇㄦ），拆回一字一音"""
    out = []
    for s in syls:
        if len(s) > 1 and s.endswith('ㄦ'):
            out += [s[:-1], 'ㄦ˙']
        else:
            out.append(s)
    if len(out) != len(word):
        return None
    # 拆出來的 ㄦ 必須正好對到「兒」字
    for ch, s in zip(word, out):
        if s == 'ㄦ˙' and ch != '兒':
            return None
    return out


def syllable_code(syl, table):
    """一個注音音節（如 ˙ㄇㄜ、ㄧㄤˋ）→ terra 碼（me5、yang4）"""
    tone = '1'
    if syl.startswith('˙'):
        tone, syl = '5', syl[1:]
    elif syl and syl[-1] in TONES:
        tone, syl = TONES[syl[-1]], syl[:-1]
    base = table.get(syl)
    return base + tone if base else None


def moe_rows(table, essay):
    skipped = erhua = 0
    data = json.load(lzma.open(MOE, 'rt', encoding='utf-8'))
    char_codes = {}   # 單字 → 讀音（給異體字沿用）
    variants = []     # (異體字, 本字)
    for entry in data:
        word = entry.get('title', '')
        if not CJK.match(word) or len(word) > 8:
            continue
        for h in entry.get('heteronyms', []):
            if not h.get('bopomofo'):
                for d in h.get('definitions', []):
                    m = re.match(r'^「(.)」的異體字', d.get('def', ''))
                    if m and len(word) == 1:
                        variants.append((word, m.group(1)))
                continue
            bpmf = re.sub(r'（[^）]*）|\([^)]*\)', ' ', h['bopomofo']).replace('　', ' ')
            syls = bpmf.split()
            if len(syls) != len(word):
                syls = split_erhua(word, syls)
                if not syls:
                    skipped += 1
                    continue
                erhua += 1
            codes = [syllable_code(s, table) for s in syls]
            if None in codes:
                skipped += 1
                continue
            if len(word) == 1:
                char_codes.setdefault(word, []).append(codes)
            yield word, codes
            # 兒化詞的「兒」也接受二聲（ㄦˊ）
            if '兒' in word:
                alt = [('er2' if c == 'er5' and ch == '兒' else c) for ch, c in zip(word, codes)]
                if alt != codes:
                    yield word, alt
    n_var = 0
    for var, base in variants:
        for codes in char_codes.get(base, []):
            n_var += 1
            yield var, codes
    print(f'教育部辭典：兒化音 {erhua}、異體字讀音 {n_var}、無法轉換略過 {skipped}')


def chewing_rows(table):
    """新酷音詞庫：保留臺灣舊讀音與習慣讀音（垃圾 ㄌㄜˋ ㄙㄜˋ、期 ㄑㄧˊ、微 ㄨㄟˊ）"""
    skipped = 0
    for name in ('chewing-word.csv', 'chewing-tsi.csv'):
        for line in (HERE / name).read_text(encoding='utf-8').splitlines():
            if line.startswith('#'):
                continue
            parts = line.split(',')
            if len(parts) != 3 or not CJK.match(parts[0]) or len(parts[0]) > 8:
                continue
            word, freq, bpmf = parts
            syls = bpmf.split()
            codes = [syllable_code(s, table) for s in syls]
            if len(syls) != len(word) or None in codes:
                skipped += 1
                continue
            yield word, codes, int(freq or 0)
    print(f'新酷音詞庫：無法轉換略過 {skipped}')


def main():
    table = zhuyin_to_pinyin_table()
    readings = char_readings()
    essay = {}
    for line in (RIME_DATA / 'essay.txt').read_text(encoding='utf-8').splitlines():
        w, _, n = line.partition('\t')
        essay[w] = n

    seen = set()
    rows = []

    def add(word, codes, weight):
        key = (word, tuple(codes))
        if key not in seen:
            seen.add(key)
            rows.append(f'{word}\t{" ".join(codes)}\t{weight}')

    # terra_pinyin 已有的單字讀音；重複列出會覆蓋原本的權重，所以只補沒有的
    terra_chars = set()
    body = (RIME_DATA / 'terra_pinyin.dict.yaml').read_text(encoding='utf-8').split('\n...\n', 1)[1]
    for line in body.splitlines():
        parts = line.split('\t')
        if len(parts) >= 2 and len(parts[0]) == 1:
            terra_chars.add((parts[0], parts[1]))

    n_moe = n_char = 0
    for word, codes in moe_rows(table, essay):
        n_moe += 1
        if len(word) == 1:
            if (word, codes[0]) not in terra_chars:
                add(word, codes, '1%')  # 補上內建沒有的破音讀音，權重低於常用讀音
                n_char += 1
            continue
        weight = essay.get(word, '1')
        add(word, codes, weight)
        add(word, sandhi(word, codes), weight)

    # 新酷音：舊讀音、習慣讀音（單字只補內建沒有的讀音）
    n_chewing = 0
    for word, codes, freq in chewing_rows(table):
        if len(word) == 1:
            if (word, codes[0]) not in terra_chars and (word, tuple(codes)) not in seen:
                add(word, codes, '1%')
                n_char += 1
            continue
        before = len(rows)
        weight = essay.get(word, str(max(freq, 1)))
        add(word, codes, weight)
        add(word, sandhi(word, codes), weight)
        n_chewing += len(rows) - before
    print(f'新酷音補充詞讀音 {n_chewing}')

    # 教育部沒收、但內建詞彙有的「一」「不」詞：補變調並保留原讀音
    moe_words = {r.split('\t')[0] for r in rows}
    for word, weight in essay.items():
        if word in moe_words or len(word) < 2 or ('一' not in word[:-1] and '不' not in word[:-1]):
            continue
        if not all(c in readings for c in word):
            continue
        codes = [readings[c] for c in word]
        new = sandhi(word, codes)
        if new != codes:
            add(word, new, weight)
            add(word, codes, weight)

    OUT.write_text(HEADER + '\n'.join(rows) + '\n', encoding='utf-8', newline='\n')
    print(f'教育部讀音 {n_moe} 個（新增單字讀音 {n_char}）；詞庫共 {len(rows)} 筆 → {OUT}')


if __name__ == '__main__':
    main()
