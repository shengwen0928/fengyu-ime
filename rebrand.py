"""風語輸入法 — 將小狼毫（Weasel）原始碼改為 AIW 風光Ai窗 品牌。

用法：python rebrand.py <weasel 原始碼目錄>
可重複執行（已替換過的字串不會再被改動）。
"""
import sys
from pathlib import Path

NAME = '風語輸入法'
NAME_EN = 'Fengyu IME'
COMPANY = 'AIW 風光Ai窗'
VERSION = (1, 0, 1)

# 順序重要：先替換長字串，避免出現「風語輸入法輸入法」
ZH_RULES = [
    ('小狼毫輸入法', NAME),
    ('小狼毫输入法', NAME),
    ('小狼毫', NAME),
]

# 檔案相對路徑 → 額外的精確替換（舊字串, 新字串）
EXTRA_RULES = {
    'include/WeaselUtility.h': [('return L"Weasel";', f'return L"{NAME_EN}";')],
    'output/install.nsi': [
        ('"CompanyName" "式恕堂"', f'"CompanyName" "{COMPANY}"'),
        ('"Publisher" "式恕堂"', f'"Publisher" "{COMPANY}"'),
        ('OutFile "archives\\weasel-${PRODUCT_VERSION}-installer.exe"',
         'OutFile "archives\\fengyu-ime-${PRODUCT_VERSION}-installer.exe"'),
        # 介面上不顯示上游資訊（LICENSE.txt 仍隨程式安裝，依授權保留）
        ('"Comments" "Powered by RIME | 中州韻輸入法引擎"', f'"Comments" "{COMPANY}"'),
        ('"LegalCopyright" "Copyleft RIME Developers"', f'"LegalCopyright" "{COMPANY}"'),
        ('!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"\n', ''),
        ('!insertmacro MUI_PAGE_LICENSE "LICENSE.txt"\r\n', ''),
        ('  WriteRegStr HKLM "${REG_UNINST_KEY}" "URLInfoAbout" "https://rime.im/"\n', ''),
        ('  WriteRegStr HKLM "${REG_UNINST_KEY}" "URLInfoAbout" "https://rime.im/"\r\n', ''),
        ('  WriteRegStr HKLM "${REG_UNINST_KEY}" "HelpLink" "https://rime.im/docs/"\n', ''),
        ('  WriteRegStr HKLM "${REG_UNINST_KEY}" "HelpLink" "https://rime.im/docs/"\r\n', ''),
    ],
    # 風語輸入法自己的版本號
    'build.bat': [
        ('set VERSION_MAJOR=0', f'set VERSION_MAJOR={VERSION[0]}'),
        ('set VERSION_MINOR=17', f'set VERSION_MINOR={VERSION[1]}'),
        ('set VERSION_PATCH=4', f'set VERSION_PATCH={VERSION[2]}'),
    ],
}

# 工作列選單移除上游的「說明文件」「參加討論」「檢查新版本」（各語系）
MENU_REMOVE = ['ID_WEASELTRAY_WIKI', 'ID_WEASELTRAY_FORUM', 'ID_WEASELTRAY_CHECKUPDATE']

TARGET_GLOBS = ['**/*.rc', 'output/install.nsi', 'include/WeaselUtility.h', 'build.bat']


def read(path: Path):
    raw = path.read_bytes()
    if raw.startswith(b'\xff\xfe'):
        return raw[2:].decode('utf-16-le'), 'utf-16-le', b'\xff\xfe'
    if raw.startswith(b'\xef\xbb\xbf'):
        return raw[3:].decode('utf-8'), 'utf-8', b'\xef\xbb\xbf'
    return raw.decode('utf-8'), 'utf-8', b''


def main(root: Path):
    files = sorted({p for g in TARGET_GLOBS for p in root.glob(g)
                    if '.git' not in p.parts and p.parts[len(root.parts)] not in ('librime', 'plum')})
    total = 0
    for path in files:
        text, enc, bom = read(path)
        rel = path.relative_to(root).as_posix()
        new = text
        for old, rep in EXTRA_RULES.get(rel, []):
            new = new.replace(old, rep)
        for old, rep in ZH_RULES:
            new = new.replace(old, rep)
        if rel == 'WeaselServer/WeaselServer.rc':
            lines = new.split('\n')
            kept = []
            for l in lines:
                if 'MENUITEM' in l and any(m in l for m in MENU_REMOVE):
                    continue
                if 'MENUITEM SEPARATOR' in l and kept and 'MENUITEM SEPARATOR' in kept[-1]:
                    continue  # 移除項目後避免連續兩條分隔線
                kept.append(l)
            new = '\n'.join(kept)
        if new != text:
            n = sum(text.count(o) for o, _ in ZH_RULES[2:]) + \
                sum(text.count(o) for o, _ in EXTRA_RULES.get(rel, []))
            total += n
            path.write_bytes(bom + new.encode(enc))
            print(f'{rel}: {n} 處')
    print(f'合計 {total} 處')


if __name__ == '__main__':
    main(Path(sys.argv[1]).resolve())
