"""蒸餾資料產生器：以目前安裝的風語引擎（teacher）產生 大千按鍵 -> 輸出 的資料集。

用法：python generate.py [--out dataset.jsonl] [--seed N] [--words N] [--sentences N]
全新程式碼；只透過 ctypes 驅動 fengyucore.dll。
每筆案例各開一個全新子程序＋全新暫存使用者資料夾（學習與前後文狀態不跨案例）。
"""
import argparse
import ctypes as C
import json
import multiprocessing as mp
import os
import random
import re
import shutil
import tempfile
import time
from pathlib import Path

BUILD = Path(r'C:/fengyu-build')
DICT = BUILD / 'schema' / 'fengyu.dict.yaml'
TSI = BUILD / 'tools' / 'chewing-tsi.csv'
EVAL = BUILD / 'tools' / 'eval_typing.py'
ENG = BUILD / 'tools' / 'english-10000.txt'
SHARED = BUILD / 'output' / 'data'
HERE = Path(__file__).resolve().parent

# ---- 拼音 -> 注音 -> 大千鍵位 ----
P2Z = [
    (r'^m(\d)$', r'mu\1'), (r'^r5$', 'er5'), ('iu', 'iou'), ('ui', 'uei'), ('ong', 'ung'),
    (r'^yi?', 'i'), (r'^wu?', 'u'), ('iu', 'v'), (r'^([jqx])u', r'\1v'), (r'([iuv])n', r'\1en'),
    (r'^zhi?', 'Z'), (r'^chi?', 'C'), (r'^shi?', 'S'), (r'^([zcsr])i', r'\1'),
    ('ai', 'A'), ('ei', 'I'), ('ao', 'O'), ('ou', 'U'), ('ang', 'K'), ('eng', 'G'),
    ('an', 'M'), ('en', 'N'), ('er', 'R'), ('eh', 'E'), (r'([iv])e', r'\1E'),
]
KEYMAP = str.maketrans('bpmfdtnlgkhjqxZCSrzcsiuvaoeEAIOUMNKGR12345',
                       '1qaz2wsxedcrfv5tgbyhnujm8ik,9ol.0p;/- 6347')
ROWS = ['1234567890-', 'qwertyuiop', 'asdfghjkl;', 'zxcvbnm,./']
TONE = set('3467 ')


def py_to_keys(py):
    for pat, rep in P2Z:
        py = re.sub(pat, rep, py)
    return py.translate(KEYMAP)


def neighbors():
    pos = {ch: (r, c) for r, row in enumerate(ROWS) for c, ch in enumerate(row)}
    out = {}
    for ch, (r, c) in pos.items():
        out[ch] = [ROWS[r + dr][c + dc] for dr in (-1, 0, 1) for dc in (-1, 0, 1)
                   if (dr, dc) != (0, 0) and 0 <= r + dr < 4 and 0 <= c + dc < len(ROWS[r + dr])
                   and ROWS[r + dr][c + dc] not in TONE]
    return out


def load_readings():
    """詞 -> 權重最高的讀音（拼音含聲調）。"""
    best = {}
    body = DICT.read_text(encoding='utf-8').split('\n...\n', 1)[1]
    for line in body.splitlines():
        p = line.split('\t')
        if len(p) < 2 or line.startswith('#'):
            continue
        w = p[2] if len(p) > 2 else '0'
        try:
            wt = float(w.rstrip('%')) / 100 if w.endswith('%') else float(w or 0)
        except ValueError:
            wt = 0
        if p[0] not in best or wt > best[p[0]][1]:
            best[p[0]] = (p[1], wt)
    return {k: v[0] for k, v in best.items()}


def text_keys(text, readings):
    keys, i = '', 0
    while i < len(text):
        for n in range(min(6, len(text) - i), 0, -1):
            w = text[i:i + n]
            if w in readings:
                keys += ''.join(py_to_keys(p) for p in readings[w].split())
                i += n
                break
        else:
            return None
    return keys


def load_sentences():
    src = EVAL.read_text(encoding='utf-8')
    block = src.split('SENTENCES = [', 1)[1].split('\n]', 1)[0]
    return re.findall(r"'([^']+)'", block)


def load_tsi():
    rows = []
    for line in TSI.read_text(encoding='utf-8').splitlines():
        if line.startswith('#'):
            continue
        p = line.split(',')
        if len(p) >= 3 and p[1].isdigit() and re.fullmatch(r'[\u4e00-\u9fff]+', p[0]):
            rows.append((p[0], int(p[1])))
    rows.sort(key=lambda x: -x[1])
    return rows


# ---- 引擎 ----
class Traits(C.Structure):
    _fields_ = [('data_size', C.c_int), ('shared_data_dir', C.c_char_p), ('user_data_dir', C.c_char_p),
                ('distribution_name', C.c_char_p), ('distribution_code_name', C.c_char_p),
                ('distribution_version', C.c_char_p), ('app_name', C.c_char_p),
                ('modules', C.c_void_p), ('min_log_level', C.c_int), ('log_dir', C.c_char_p),
                ('prebuilt_data_dir', C.c_char_p), ('staging_dir', C.c_char_p)]


class Commit(C.Structure):
    _fields_ = [('data_size', C.c_int), ('text', C.c_char_p)]


class Composition(C.Structure):
    _fields_ = [('length', C.c_int), ('cursor_pos', C.c_int), ('sel_start', C.c_int),
                ('sel_end', C.c_int), ('preedit', C.c_char_p)]


class Candidate(C.Structure):
    _fields_ = [('text', C.c_char_p), ('comment', C.c_char_p), ('reserved', C.c_void_p)]


class Menu(C.Structure):
    _fields_ = [('page_size', C.c_int), ('page_no', C.c_int), ('is_last_page', C.c_int),
                ('highlighted_candidate_index', C.c_int), ('num_candidates', C.c_int),
                ('candidates', C.POINTER(Candidate)), ('select_keys', C.c_char_p)]


class Context(C.Structure):
    _fields_ = [('data_size', C.c_int), ('composition', Composition), ('menu', Menu),
                ('commit_text_preview', C.c_char_p), ('select_labels', C.c_void_p)]


class Teacher:
    def __init__(self):
        app = max(Path(r'C:/Program Files/Fengyu').glob('fengyu-*'))
        self.work = Path(tempfile.mkdtemp(prefix='fengyu_distill_'))
        user = self.work / 'user'
        user.mkdir()
        os.add_dll_directory(str(app))
        self.e = C.CDLL(str(app / 'fengyucore.dll'))
        t = Traits()
        t.data_size = C.sizeof(Traits) - C.sizeof(C.c_int)
        t.shared_data_dir = str(SHARED).encode()
        t.user_data_dir = str(user).encode()
        t.distribution_name = b'fengyu-distill'
        t.distribution_code_name = b'Fengyu'
        t.distribution_version = b'0'
        t.app_name = b'fengyu-distill'
        t.min_log_level = 2
        t.log_dir = str(self.work).encode()
        self.e.RimeSetup(C.byref(t))
        self.e.RimeInitialize(C.byref(t))
        self.e.RimeStartMaintenance(False)
        self.e.RimeJoinMaintenanceThread()
        self.e.RimeCreateSession.restype = C.c_size_t

    def _commit(self, sid):
        c = Commit()
        c.data_size = C.sizeof(Commit) - C.sizeof(C.c_int)
        if self.e.RimeGetCommit(C.c_size_t(sid), C.byref(c)):
            s = c.text.decode()
            self.e.RimeFreeCommit(C.byref(c))
            return s
        return ''

    def _context(self, sid):
        ctx = Context()
        ctx.data_size = C.sizeof(Context) - C.sizeof(C.c_int)
        if not self.e.RimeGetContext(C.c_size_t(sid), C.byref(ctx)):
            return '', []
        pre = (ctx.composition.preedit or b'').decode()
        cands = [ctx.menu.candidates[i].text.decode() for i in range(min(ctx.menu.num_candidates, 5))]
        self.e.RimeFreeContext(C.byref(ctx))
        return pre, cands

    def run(self, keys):
        """新 session 逐鍵送入並每鍵讀 context；回傳 (output, preedit, candidates)。
        preedit/candidates 為按 Enter 之前最後的狀態；output 為過程中與 Enter 後所有送出文字。"""
        sid = self.e.RimeCreateSession()
        out, pre, cands = '', '', []
        for tok in keys:
            self.e.RimeSimulateKeySequence(C.c_size_t(sid), ('{space}' if tok == ' ' else tok).encode())
            out += self._commit(sid)
            pre, cands = self._context(sid)
        self.e.RimeSimulateKeySequence(C.c_size_t(sid), b'{Return}')
        out += self._commit(sid)
        self.e.RimeDestroySession(C.c_size_t(sid))
        return out, pre, cands

    def close(self):
        self.e.RimeFinalize()
        shutil.rmtree(self.work, ignore_errors=True)


CATEGORY = {'word': 'chinese', 'char': 'chinese', 'sentence': 'chinese', 'typo': 'typo',
            'english': 'english', 'abbr': 'english', 'number': 'number',
            'mixed_zh_en': 'mixed', 'mixed_en_zh': 'mixed', 'mixed_zh_num': 'mixed'}


def run_isolated(case):
    """子程序入口：全新引擎＋全新使用者資料夾，只跑一筆。"""
    kind, text, keys = case
    t = Teacher()
    try:
        out, pre, cands = t.run(keys)
    finally:
        t.close()
    # 老師疑似有誤：空輸出，或 中文＋數字 案例輸出與意圖不符（數字被當注音／吞字）
    suspect = out == '' or (kind == 'mixed_zh_num' and out != text)
    return {'keys': keys, 'output': out, 'preedit': pre, 'candidates': cands, 'kind': kind,
            'category': CATEGORY[kind], 'expected': text, 'isolated': True,
            'teacher_suspect': suspect}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=str(HERE / 'dataset.jsonl'))
    ap.add_argument('--seed', type=int, default=20261007)
    ap.add_argument('--words', type=int, default=2500)
    ap.add_argument('--sentences', type=int, default=1500)
    ap.add_argument('--english', type=int, default=900)
    ap.add_argument('--typos', type=int, default=600)
    ap.add_argument('--jobs', type=int, default=max(1, (os.cpu_count() or 4) // 2))
    a = ap.parse_args()
    rnd = random.Random(a.seed)
    readings = load_readings()
    nb = neighbors()
    tsi = load_tsi()
    multi = [w for w, _ in tsi if len(w) >= 2][:6000]
    singles = [w for w, _ in tsi if len(w) == 1][:1500]

    cases, seen = [], set()

    def add(kind, text, keys):
        if keys and keys not in seen:
            seen.add(keys)
            cases.append((kind, text, keys))
            return True
        return False

    for s in load_sentences():
        add('sentence', s, text_keys(s, readings))
    for w in singles[:400]:
        add('char', w, text_keys(w, readings))
    nw = 0
    for w in multi:
        if nw >= a.words:
            break
        nw += add('word', w, text_keys(w, readings))
    # 以高頻詞隨機組句（2~4 詞）
    pool = multi[:3000] + singles[:300]
    n = 0
    while n < a.sentences:
        text = ''.join(rnd.choice(pool) for _ in range(rnd.randint(2, 4)))
        if len(text) <= 12:
            k = text_keys(text, readings)
            if k:
                n += add('sentence', text, k)
    # 打錯相鄰鍵
    base = [c for c in cases if c[0] in ('sentence', 'word')]
    for _ in range(a.typos):
        kind, text, keys = rnd.choice(base)
        idx = [i for i, k in enumerate(keys) if k not in TONE and nb.get(k)]
        if not idx:
            continue
        i = rnd.choice(idx)
        add('typo', text, keys[:i] + rnd.choice(nb[keys[i]]) + keys[i + 1:])
    # 中英數混合
    eng = [w.lower() for w in ENG.read_text(encoding='utf-8').split() if w.isalpha() and len(w) >= 2]
    eng_top = eng[:3000]
    zh = multi[:1500]
    for _ in range(a.english):
        r = rnd.random()
        e = rnd.choice(eng_top)
        z = rnd.choice(zh)
        zk = text_keys(z, readings)
        if r < 0.25:
            add('english', e, e + ' ')
        elif r < 0.5:
            add('mixed_zh_en', z + ' ' + e, zk + e + ' ')
        elif r < 0.7:
            add('mixed_en_zh', e + ' ' + z, e + ' ' + zk)
        elif r < 0.85:
            num = str(rnd.choice([rnd.randint(0, 99), rnd.randint(100, 99999), rnd.randint(1990, 2030)]))
            add('number', num, num)
        else:
            num = str(rnd.randint(1, 9999))
            add('mixed_zh_num', z + num, zk + num)
    for ab in ['USB', 'PDF', 'CPU', 'GPU', 'API', 'LINE', 'iPhone', 'Wi-Fi', 'AI', 'IT', 'ok', 'OK', 'ID', 'PC']:
        add('abbr', ab, ab + ' ')

    print(f'案例數 {len(cases)}', flush=True)
    t0 = time.time()
    counts, sus = {}, {}
    with open(a.out, 'w', encoding='utf-8', newline='\n') as f, \
            mp.get_context('spawn').Pool(a.jobs, maxtasksperchild=1) as pool:
        for i, rec in enumerate(pool.imap(run_isolated, cases, chunksize=1)):
            f.write(json.dumps(rec, ensure_ascii=False) + '\n')
            counts[rec['kind']] = counts.get(rec['kind'], 0) + 1
            if rec['teacher_suspect']:
                sus[rec['kind']] = sus.get(rec['kind'], 0) + 1
            if i % 200 == 0:
                print(i, f'{time.time() - t0:.0f}s', flush=True)
    print('可疑', sus)
    print('完成', len(cases), counts, f'{time.time() - t0:.0f}s')


if __name__ == '__main__':
    main()
