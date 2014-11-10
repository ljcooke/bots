#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
@everyhaiku by @inky
2009-12-08, 2014-11-09

Usage:

    python haiku.py
        Generate a haiku.

    python haiku.py json
        Generate a haiku and print the lines in JSON.

"""
import json
import sys
from random import choice

try:
    from tweet import post_tweet
except ImportError:
    post_tweet = None

KANA_MAP = {
    'a': u'あかさたなはまやらわ' * 2 + u'がざだばぱ',
    'i': u'いきしちにひみり' * 2 + u'ぎじびぴ',
    'u': u'うくすつぬふむゆる' * 2 + u'ぐずぶぷ',
    'e': u'えけせてねへめれ' * 2 + u'げぜでべぺ',
    'o': u'おこそとのほもよろを' * 2 + u'ごぞどぼぽ',
}
ROMAJI_MAP = {
    'a': 'a ka sa ta na ha ma ya ra wa'.split() * 2 + 'ga za da ba pa'.split(),
    'i': 'i ki shi chi ni hi mi ri'.split() * 2 + 'gi ji bi pi'.split(),
    'u': 'u ku su tsu nu fu mu yu ru'.split() * 2 + 'gu zu bu pu'.split(),
    'e': 'e ke se te ne he me re'.split() * 2 + 'ge ze de be pe'.split(),
    'o': 'o ko so to no ho mo yo ro wo'.split() * 2 + 'go zo do bo po'.split(),
}

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
        return '\n'.join(ja.ljust(8, u'\u3000') + en
                         for ja, en in zip(haiku['ja'], haiku['en']))

def main():
    gen = HaikuGen()
    haiku = gen.haiku()
    if post_tweet and 'tweet' in sys.argv:
        post_tweet(gen.format(haiku))
    elif 'json' in sys.argv:
        print(json.dumps(haiku))
    else:
        print(gen.format(haiku))

if __name__ == '__main__':
    main()
