"""風語輸入法 — 本機模擬打字測試（直接呼叫 rime.dll，不經過 Windows 輸入法）。

用法：python rime_test.py "hello " "su3hello " "ru " "ru{Return}"
會把使用者資料夾複製到暫存目錄測試，不影響正在使用的輸入法。

      python rime_test.py --build "hello " "su3cl3 "
改測剛編譯好的 output/（不必先安裝），並以空的使用者資料夾模擬全新安裝。
"""
import ctypes as C
import os
import shutil
import sys
import tempfile
from pathlib import Path

RIME_DIR = None  # None＝目前安裝的版本（main 執行時才尋找）
USER_DIR = Path(os.environ['APPDATA']) / 'Fengyu'
BUILD_DIR = Path(__file__).resolve().parent.parent / 'output'  # --build 測試的編譯產出


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


def show_context(rime, sid):
    ctx = Context()
    ctx.data_size = C.sizeof(Context) - C.sizeof(C.c_int)
    if not rime.RimeGetContext(C.c_size_t(sid), C.byref(ctx)):
        return ''
    pre = (ctx.composition.preedit or b'').decode()
    cands = [ctx.menu.candidates[i].text.decode() for i in range(min(ctx.menu.num_candidates, 5))]
    rime.RimeFreeContext(C.byref(ctx))
    return f'組字區 {pre!r} 候選 {cands}'


def main(cases, build=False):
    work = Path(tempfile.mkdtemp(prefix='fengyu_test_'))
    user = work / 'user'
    if build:
        rime_dir = BUILD_DIR
        user.mkdir()  # 空的使用者資料夾＝全新安裝
    else:
        rime_dir = RIME_DIR or max(Path(r'C:/Program Files/Fengyu').glob('fengyu-*'))
        skip = ['*.userdb'] + (['*.gram'] if os.environ.get('FENGYU_NO_GRAMMAR') else [])  # 比較有無語言模型
        shutil.copytree(USER_DIR, user, ignore=shutil.ignore_patterns(*skip))
    os.add_dll_directory(str(rime_dir))
    rime = C.CDLL(str(rime_dir / 'rime.dll'))
    t = Traits()
    t.data_size = C.sizeof(Traits) - C.sizeof(C.c_int)
    t.shared_data_dir = str(rime_dir / 'data').encode()
    t.user_data_dir = str(user).encode()
    t.distribution_name = b'fengyu-test'
    t.distribution_code_name = b'Fengyu'
    t.distribution_version = b'0'
    t.app_name = b'rime.fengyu_test'
    t.min_log_level = 2
    t.log_dir = str(work).encode()
    rime.RimeSetup(C.byref(t))
    rime.RimeInitialize(C.byref(t))
    rime.RimeStartMaintenance(False)
    rime.RimeJoinMaintenanceThread()
    rime.RimeCreateSession.restype = C.c_size_t
    for case in cases:
        sid = rime.RimeCreateSession()
        seq = case.replace(' ', '{space}')
        rime.RimeSimulateKeySequence(C.c_size_t(sid), seq.encode())
        c = Commit()
        c.data_size = C.sizeof(Commit) - C.sizeof(C.c_int)
        out = ''
        if rime.RimeGetCommit(C.c_size_t(sid), C.byref(c)):
            out = c.text.decode()
            rime.RimeFreeCommit(C.byref(c))
        print(f'{case!r:24} → 送出 {out!r:14} {show_context(rime, sid)}')
        rime.RimeDestroySession(C.c_size_t(sid))
    rime.RimeFinalize()
    errs = [p for p in work.glob('*.ERROR*')] + [p for p in work.glob('*.WARNING*')]
    for p in errs:
        print('--', p.name)
        print(p.read_text(encoding='utf-8', errors='replace')[-1500:])


if __name__ == '__main__':
    args = sys.argv[1:]
    build = bool(args) and args[0] == '--build'
    main(args[1:] if build else args, build=build)
