"""風語輸入法 — 產生「一」「不」變調詞庫（schema/fengyu.dict.yaml）。

用法：python gen_sandhi.py
照實際讀音打也能出字，例如 ㄧˊ ㄧㄤˋ → 一樣、ㄧˋ ㄑㄧˇ → 一起、ㄅㄨˊ ㄧㄠˋ → 不要。
規則：一 + 四聲/輕聲 → 二聲；一 + 一二三聲 → 四聲；不 + 四聲 → 二聲（詞尾的一、不不變調）。
"""
from pathlib import Path

from gen_english import INSTALL_DATA
OUT = Path(__file__).resolve().parent.parent / 'schema' / 'fengyu.dict.yaml'

HEADER = """# 風語輸入法（AIW 風光Ai窗）— 詞庫
# 由 tools/gen_sandhi.py 產生，請勿手動修改
---
name: fengyu
version: "1.0.0"
sort: by_weight
use_preset_vocabulary: true
import_tables:
  - terra_pinyin
...
"""


def char_readings():
    """每個字最常用的讀音"""
    body = (INSTALL_DATA / 'terra_pinyin.dict.yaml').read_text(encoding='utf-8').split('\n...\n', 1)[1]
    best = {}
    for line in body.splitlines():
        parts = line.split('\t')
        if len(parts) < 2 or len(parts[0]) != 1 or line.startswith('#'):
            continue
        w = float(parts[2].rstrip('%')) if len(parts) > 2 and parts[2].endswith('%') else 100.0
        if parts[0] not in best or w > best[parts[0]][1]:
            best[parts[0]] = (parts[1], w)
    return {c: r for c, (r, _) in best.items()}


def sandhi(word, codes):
    out = list(codes)
    for i, ch in enumerate(word[:-1]):
        nxt = codes[i + 1][-1]
        if ch == '一' and codes[i] == 'yi1':
            out[i] = 'yi2' if nxt in '45' else 'yi4'
        elif ch == '不' and codes[i] == 'bu4' and nxt == '4':
            out[i] = 'bu2'
    return out


def main():
    readings = char_readings()
    rows = []
    for line in (INSTALL_DATA / 'essay.txt').read_text(encoding='utf-8').splitlines():
        word, _, weight = line.partition('\t')
        if len(word) < 2 or ('一' not in word[:-1] and '不' not in word[:-1]):
            continue
        if not all(c in readings for c in word):
            continue
        codes = [readings[c] for c in word]
        new = sandhi(word, codes)
        if new != codes:
            # 詞一旦寫進詞庫，預設詞彙就不再自動補讀音，所以原讀音也要一併列出
            rows.append(f'{word}\t{" ".join(new)}\t{weight}')
            rows.append(f'{word}\t{" ".join(codes)}\t{weight}')
    OUT.write_text(HEADER + '\n'.join(rows) + '\n', encoding='utf-8', newline='\n')
    print(f'變調詞 {len(rows)} 筆 → {OUT}')


if __name__ == '__main__':
    main()
