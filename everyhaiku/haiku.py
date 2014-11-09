#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
@everyhaiku by @inky
2009-12-08, 2014-11-09

Run `python haiku.py` to generate a random haiku.

"""
import sys
from random import choice

try:
    from tweet import post_tweet
except ImportError:
    post_tweet = None

KANA_MAP = dict(
    a = u'あかさたなはまやらわ',
    i = u'いきしちにひみり',
    u = u'うくすつぬふむゆる',
    e = u'えけせてねへめれ',
    o = u'おこそとのほもよろを',
)
ROMAJI_MAP = dict(
    a = 'a ka sa ta na ha ma ya ra wa'.split(),
    i = 'i ki shi chi ni hi mi ri'.split(),
    u = 'u ku su tsu nu fu mu yu ru'.split(),
    e = 'e ke se te ne he me re'.split(),
    o = 'o ko so to no ho mo yo ro wo'.split(),
)

class HaikuGen(object):

    def __init__(self):
        self.keys = KANA_MAP.keys()
        self.kana = tuple(''.join(KANA_MAP.values()))
        self.line_start = tuple(k for k in self.kana if k != u'を')
        self.romaji = {}
        for key in self.keys:
            self.romaji.update(zip(KANA_MAP[key], ROMAJI_MAP[key]))

    def haiku(self):
        verse_ja, verse_en = [], []
        final = None

        # generate three lines
        for mora in (5, 7, 5):
            # first kana in the line -- any but を, the direct object marker
            line = [choice(self.line_start)]
            # generate more up to the second-last kana
            line += [choice(self.kana) for _ in range(mora - 2)]
            # last kana; check the vowel to avoid rhyming with the preceding line
            sounds = tuple(s for s in self.keys if s != final) if final else self.keys
            final = choice(sounds)
            line += [choice(KANA_MAP[final])]
            # stitch the line together and add it to the verse
            line = ''.join(line)
            verse_ja.append(line)
            verse_en.append(' '.join(self.romaji[kana] for kana in line))

        return {'ja': verse_ja,
                'en': verse_en}

    def format(self, haiku):
        ja, en = haiku['ja'], haiku['en']
        return '\n'.join( [''.join(ja)] + en )

def main():
    gen = HaikuGen()
    haiku = gen.format(gen.haiku())
    if post_tweet and 'tweet' in sys.argv:
        post_tweet(haiku)
    else:
        print(haiku)

if __name__ == '__main__':
    main()
