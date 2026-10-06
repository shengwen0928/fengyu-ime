"""風語輸入法 — 整句選字準確率評估（測試用）。

用法：python eval_typing.py <共用資料夾> [<共用資料夾> ...]
  每個共用資料夾是一份完整的 data\（可換不同語言模型或拼寫規則來比較）。
  對 SENTENCES 每句：依詞庫讀音轉成大千按鍵，逐鍵送進引擎、最後按 Enter，
  比對送出的整句。另外各產生一份「隨機打錯一個相鄰按鍵」的版本，看能否還原。
  引擎用目前安裝的 fengyucore.dll。
"""
import ctypes as C
import os
import random
import re
import sys
import tempfile
from pathlib import Path

import fengyu_test as ft
from gen_english import to_keys

HERE = Path(__file__).resolve().parent
SCHEMA = HERE.parent / 'schema'

SENTENCES = [
    '我今天要去台北開會', '這個選字不太對', '請幫我確認一下時間', '明天下午三點見面',
    '我們公司在新北市', '這家餐廳的牛肉麵很好吃', '你可以先把資料寄給我嗎', '我想訂兩張高鐵票',
    '他說等一下會打電話給你', '這份報價單需要主管簽名', '颱風來了記得關好門窗', '週末要不要一起去看電影',
    '這台電腦的速度太慢了', '請問捷運站怎麼走', '我已經把檔案上傳到雲端', '下雨天路上要小心',
    '這個問題我們開會再討論', '謝謝你的幫忙', '老師說明天要考試', '我覺得這個設計很漂亮',
    '鋁門窗的尺寸要重新丈量', '工地明天開始施工', '玻璃的厚度是八毫米', '客戶希望下週交貨',
    '請把發票開給公司', '這款手機的電池很耐用', '晚上要不要吃火鍋', '輸入法的選字越來越準確',
    '我在找停車位', '這本書的內容很有趣', '你的意見很重要', '今天的天氣很適合出去玩',
    '他是我大學的同學', '我們一起努力完成這個專案', '請記得帶身分證', '這件衣服有其他顏色嗎',
    '冷氣好像壞掉了', '機場接駁車幾點出發', '這個月的營業額成長了', '小心不要感冒',
]

ROWS = ['1234567890-', 'qwertyuiop', 'asdfghjkl;', 'zxcvbnm,./']
TONE_KEYS = set('3467 ')


def neighbors():
    pos = {ch: (r, c) for r, row in enumerate(ROWS) for c, ch in enumerate(row)}
    out = {}
    for ch, (r, c) in pos.items():
        cand = []
        for dr in (-1, 0, 1):
            for dc in (-1, 0, 1):
                if (dr, dc) == (0, 0):
                    continue
                rr, cc = r + dr, c + dc
                if 0 <= rr < len(ROWS) and 0 <= cc < len(ROWS[rr]):
                    cand.append(ROWS[rr][cc])
        out[ch] = [x for x in cand if x not in TONE_KEYS]
    return out


def load_readings():
    """詞 → 最常用讀音（拼音，含聲調數字）"""
    best = {}
    for name in ('terra_pinyin.dict.yaml', 'fengyu.dict.yaml'):
        body = (SCHEMA / name).read_text(encoding='utf-8').split('\n...\n', 1)[1]
        for line in body.splitlines():
            parts = line.split('\t')
            if len(parts) < 2 or line.startswith('#'):
                continue
            w = parts[2] if len(parts) > 2 else '0'
            weight = float(w.rstrip('%')) / 100 if w.endswith('%') else float(w or 0)
            if parts[0] not in best or weight > best[parts[0]][1]:
                best[parts[0]] = (parts[1], weight)
    return {k: v[0] for k, v in best.items()}


def sentence_keys(sentence, readings):
    keys, i = '', 0
    while i < len(sentence):
        for n in range(min(6, len(sentence) - i), 0, -1):
            word = sentence[i:i + n]
            if word in readings:
                keys += ''.join(to_keys(p) for p in readings[word].split())
                i += n
                break
        else:
            raise ValueError(f'no reading for {sentence[i]!r} in {sentence}')
    return keys


def typo(keys, rnd, nb):
    idx = [i for i, k in enumerate(keys) if k not in TONE_KEYS and nb.get(k)]
    i = rnd.choice(idx)
    return keys[:i] + rnd.choice(nb[keys[i]]) + keys[i + 1:]


def run(engine, sid, keys):
    out = ''
    for token in list(keys) + ['{Return}']:
        engine.RimeSimulateKeySequence(C.c_size_t(sid), (token if token != ' ' else '{space}').encode())
        c = ft.Commit()
        c.data_size = C.sizeof(ft.Commit) - C.sizeof(C.c_int)
        if engine.RimeGetCommit(C.c_size_t(sid), C.byref(c)):
            out += c.text.decode()
            engine.RimeFreeCommit(C.byref(c))
        ft.show_context(engine, sid)  # 同真實輸入法：每鍵後讀候選
    return out


def evaluate(engine, shared):
    work = Path(tempfile.mkdtemp(prefix='fengyu_eval_'))
    (work / 'user').mkdir()
    t = ft.Traits()
    t.data_size = C.sizeof(ft.Traits) - C.sizeof(C.c_int)
    t.shared_data_dir = str(shared).encode()
    t.user_data_dir = str(work / 'user').encode()
    t.distribution_name = b'fengyu-eval'
    t.distribution_code_name = b'Fengyu'
    t.distribution_version = b'0'
    t.app_name = b'fengyu-eval'
    t.min_log_level = 2
    t.log_dir = str(work).encode()
    engine.RimeSetup(C.byref(t))
    engine.RimeInitialize(C.byref(t))
    engine.RimeStartMaintenance(False)
    engine.RimeJoinMaintenanceThread()
    engine.RimeCreateSession.restype = C.c_size_t

    readings, nb, rnd = load_readings(), neighbors(), random.Random(20261006)
    clean_ok = typo_ok = 0
    misses = []
    for s in SENTENCES:
        keys = sentence_keys(s, readings)
        for kind, k in (('正確', keys), ('打錯', typo(keys, rnd, nb))):
            sid = engine.RimeCreateSession()  # 每句新 session，不受前句學習影響
            got = run(engine, sid, k)
            engine.RimeDestroySession(C.c_size_t(sid))
            if got == s:
                if kind == '正確':
                    clean_ok += 1
                else:
                    typo_ok += 1
            else:
                misses.append(f'  [{kind}] {s} → {got}')
    engine.RimeFinalize()
    return clean_ok, typo_ok, misses


def main():
    app = max(Path(r'C:/Program Files/Fengyu').glob('fengyu-*'))
    os.add_dll_directory(str(app))
    engine = C.CDLL(str(app / 'fengyucore.dll'))
    shared = Path(sys.argv[1])
    clean_ok, typo_ok, misses = evaluate(engine, shared)
    n = len(SENTENCES)
    print(f'{shared.name}: 打字正確 {clean_ok}/{n}  相鄰鍵打錯 {typo_ok}/{n}')
    print('\n'.join(misses))


if __name__ == '__main__':
    main()
