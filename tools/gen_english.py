"""風語輸入法 — 產生中英混打用的英文詞表（schema/lua/fengyu_english.lua）。

用法：python gen_english.py
- 英文詞來源：tools/english-10000.txt（google-10000-english, no swears）
- 撞鍵判斷：用 zhuyin.yaml 相同的規則，把 terra_pinyin 的一聲音節轉成大千鍵位；
  若英文字的按鍵剛好等於某個一聲注音音節，則標為 conflict（空白鍵維持注音一聲，Enter 才送英文）。
"""
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
INSTALL_DIR = max(Path(r'C:/Program Files/Fengyu').glob('fengyu-*'))  # 目前安裝的版本
INSTALL_DATA = INSTALL_DIR / 'data'
OUT = HERE.parent / 'schema' / 'lua' / 'fengyu_english.lua'

# 與 zhuyin.yaml pinyin_to_zhuyin 相同
PINYIN_TO_ZHUYIN = [
    (r'^m(\d)$', r'mu\1'), (r'^r5$', 'er5'), ('iu', 'iou'), ('ui', 'uei'), ('ong', 'ung'),
    (r'^yi?', 'i'), (r'^wu?', 'u'), ('iu', 'v'), (r'^([jqx])u', r'\1v'), (r'([iuv])n', r'\1en'),
    (r'^zhi?', 'Z'), (r'^chi?', 'C'), (r'^shi?', 'S'), (r'^([zcsr])i', r'\1'),
    ('ai', 'A'), ('ei', 'I'), ('ao', 'O'), ('ou', 'U'), ('ang', 'K'), ('eng', 'G'),
    ('an', 'M'), ('en', 'N'), ('er', 'R'), ('eh', 'E'), (r'([iv])e', r'\1E'),
]
KEYMAP = str.maketrans('bpmfdtnlgkhjqxZCSrzcsiuvaoeEAIOUMNKGR12345',
                       '1qaz2wsxedcrfv5tgbyhnujm8ik,9ol.0p;/- 6347')


def to_keys(pinyin):
    for pat, rep in PINYIN_TO_ZHUYIN:
        pinyin = re.sub(pat, rep, pinyin)
    return pinyin.translate(KEYMAP)


def syllables():
    """回傳（一聲音節按鍵集合, 所有音節去聲調後的按鍵集合）"""
    text = (INSTALL_DATA / 'terra_pinyin.dict.yaml').read_text(encoding='utf-8')
    body = text.split('\n...\n', 1)[1]
    tone1, bases = set(), set()
    for line in body.splitlines():
        parts = line.split('\t')
        if len(parts) >= 2 and not line.startswith('#'):
            for p in parts[1].split(' '):
                if not p or not p[-1].isdigit():
                    continue
                keys = to_keys(p)[:-1]  # 去掉聲調鍵
                bases.add(keys)
                if p.endswith('1'):
                    tone1.add(keys)
    return tone1, bases


def main():
    sylls, bases = syllables()
    words = []
    for w in (HERE / 'english-10000.txt').read_text(encoding='utf-8').split():
        w = w.strip().lower()
        if len(w) >= 2 and w.isascii() and w.isalpha():
            words.append(w)
    words = sorted(set(words))
    conflicts = [w for w in words if w in sylls]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open('w', encoding='utf-8', newline='\n') as f:
        f.write('-- 由 tools/gen_english.py 產生，請勿手動修改\n')
        f.write('local words = {}\nfor w in ([[\n')
        f.write('\n'.join(words))
        f.write('\n]]):gmatch("%a+") do words[w] = true end\n')
        f.write('local conflicts = {}\nfor w in ([[\n')
        f.write('\n'.join(conflicts))
        f.write('\n]]):gmatch("%a+") do conflicts[w] = true end\n')
        # 注音音節（去聲調）的大千按鍵，含數字與標點鍵，以空白分隔
        f.write('local tone1 = {}\nfor s in ([[\n')
        f.write(' '.join(sorted(sylls)))
        f.write('\n]]):gmatch("%S+") do tone1[s] = true end\n')
        f.write('local syllables = {}\nfor s in ([[\n')
        f.write(' '.join(sorted(bases)))
        f.write('\n]]):gmatch("%S+") do syllables[s] = true end\n')
        f.write('return { words = words, conflicts = conflicts, tone1 = tone1, syllables = syllables }\n')
    print(f'音節 {len(bases)} 個（一聲 {len(sylls)}）；英文詞 {len(words)} 個；撞鍵 {len(conflicts)} 個')


if __name__ == '__main__':
    main()
