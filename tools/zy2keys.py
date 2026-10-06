"""注音文字轉大千按鍵（測試用）：python zy2keys.py "ㄨㄛˇ ㄒㄧㄤˇ" """
import sys
ZY = 'ㄅㄆㄇㄈㄉㄊㄋㄌㄍㄎㄏㄐㄑㄒㄓㄔㄕㄖㄗㄘㄙㄧㄨㄩㄚㄛㄜㄝㄞㄟㄠㄡㄢㄣㄤㄥㄦ'
KEY = '1qaz2wsxedcrfv5tgbyhnujm8ik,9ol.0p;/-'
TONE = {'ˊ': '6', 'ˇ': '3', 'ˋ': '4', '˙': '7'}
def conv(text):
    out = []
    for syl in text.split():
        light = syl.startswith('˙')
        syl = syl.lstrip('˙')
        tone = TONE.get(syl[-1], None)
        if tone: syl = syl[:-1]
        out.append(''.join(KEY[ZY.index(c)] for c in syl) + ('7' if light else tone or ' '))
    return ''.join(out)
if __name__ == '__main__':
    print(' '.join(repr(conv(a)) for a in sys.argv[1:]))
