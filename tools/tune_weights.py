"""風語輸入法 — 以新酷音（台灣語料）詞頻調整權重：tools/base/ 的原始檔 → schema/。

用法：python tune_weights.py [降權除數，預設 4]
"""
import sys
from pathlib import Path

from gen_dict import syllable_code, zhuyin_to_pinyin_table

HERE = Path(__file__).resolve().parent
BASE = HERE / 'base'
SCHEMA = HERE.parent / 'schema'
DIVISOR = int(sys.argv[1]) if len(sys.argv) > 1 else 4


def chewing_freq():
    freq = {}
    for name in ('chewing-tsi.csv', 'chewing-word.csv'):
        for line in (HERE / name).read_text(encoding='utf-8').splitlines():
            parts = line.split(',')
            if line.startswith('#') or len(parts) != 3 or not parts[1].isdigit():
                continue
            freq[parts[0]] = max(freq.get(parts[0], 0), int(parts[1]))
    return freq


def tune(word, weight, freq):
    if word in freq:
        return weight + freq[word]
    if len(word) < 2:
        return weight
    return max(weight // DIVISOR, 1)


def char_reading_shares(table):
    """單字各讀音在台灣語料的比例：{(字, 碼): 比例}"""
    counts = {}
    for line in (HERE / 'chewing-tsi.csv').read_text(encoding='utf-8').splitlines():
        parts = line.split(',')
        if line.startswith('#') or len(parts) != 3 or len(parts[0]) != 1 or not parts[1].isdigit():
            continue
        code = syllable_code(parts[2], table)
        if code:
            counts[(parts[0], code)] = counts.get((parts[0], code), 0) + int(parts[1])
    totals = {}
    for (ch, _), n in counts.items():
        totals[ch] = totals.get(ch, 0) + n
    return {k: n / totals[k[0]] for k, n in counts.items() if totals[k[0]] > 0}


def main():
    freq = chewing_freq()

    essay = {}
    out = []
    for line in (BASE / 'essay.txt').read_text(encoding='utf-8').splitlines():
        w, _, n = line.partition('\t')
        if n.isdigit():
            essay[w] = tune(w, int(n), freq)
            out.append(f'{w}\t{essay[w]}')
        else:
            out.append(line)
    (SCHEMA / 'essay.txt').write_text('\n'.join(out) + '\n', encoding='utf-8', newline='\n')

    head, body = (BASE / 'fengyu.dict.yaml').read_text(encoding='utf-8').split('\n...\n', 1)
    rows = []
    for line in body.splitlines():
        parts = line.split('\t')
        if len(parts) == 3 and parts[2].isdigit():
            parts[2] = str(tune(parts[0], int(parts[2]), freq))
        rows.append('\t'.join(parts))

    # 單字讀音權重：取代 terra_pinyin 的讀音比例（如「台」唸 ㄊㄞˊ 只占 30%）
    shares = char_reading_shares(zhuyin_to_pinyin_table())
    present = {tuple(r.split('\t')[:2]) for r in rows}
    for (ch, code), share in shares.items():
        if ch in essay and (ch, code) not in present:
            rows.append(f'{ch}\t{code}\t{max(int(essay[ch] * share), 1)}')
    (SCHEMA / 'fengyu.dict.yaml').write_text(head + '\n...\n' + '\n'.join(rows) + '\n', encoding='utf-8', newline='\n')
    print(f'新酷音詞頻 {len(freq)} 筆；未收錄的多字詞權重 ÷{DIVISOR}')


if __name__ == '__main__':
    main()
