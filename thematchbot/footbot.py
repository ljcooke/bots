#!/usr/bin/env python
# coding: utf-8
import codecs
import json
import re
import sys
import unicodedata
from random import choice, randint, random
from string import uppercase as UPPERCASE

from queneau import WordAssembler


CORPUS_FILENAME = 'corpus.json'
ICONS = u'\u26BD'

VOWELS = u'aeiouáéíóúàèìòùåøæœäëïöüąęâêîôûãẽĩõũ'
STRIP_UNICODE = {
    u'æ': 'ae',
    u'œ': 'oe',
    u'ł': 'l',
    u'ø': 'o',
    u'ß': 'ss',
    u'þ': 'th',
    u'ð': 'dh',
}


class FootbotAssembler(WordAssembler):

    def __init__(self, initial=[]):
        vowels = choice((VOWELS, VOWELS + 'y'))
        self.sequence_of_vowels = re.compile("([%s]+)" % vowels, re.I)
        self.vowels = vowels + vowels.upper()
        super(FootbotAssembler, self).__init__(initial)


def flip():
    return bool(randint(0, 1))

def strip_unicode(string):
    for s, r in STRIP_UNICODE.items():
        string = string.replace(s, r)
    return ''.join(c for c in unicodedata.normalize('NFD', string)
                   if unicodedata.category(c) != 'Mn')

def random_fc():
    return choice(UPPERCASE) + choice(UPPERCASE)

def add_random_fc(string):
    r, fc = randint(1, 10), None
    if r <= 2:
        fc = 'FC'
    elif r == 3:
        fc = random_fc()
    if fc:
        return '%s %s' % choice(( (string, fc), (fc, string) ))
    else:
        return string

def format_name(team, random_fc=True, diacritics=True):
    if not diacritics:
        team = strip_unicode(team)
    team = ' '.join(w.capitalize() for w in team.split())
    if random_fc:
        team = add_random_fc(team)
    return team

def random_score():
    multiplier = 9 if random() < 0.02 else 5
    return int(random() * random() * multiplier)

def random_team(assembler):
    team = ''
    for _ in range(10):
        length = randint(3, 8)
        team = assembler.assemble_word(length=length)
        if team and all(len(w) >= 3 for w in team.split()):
            break
    return format_name(team, diacritics=flip())

def random_game(assembler):
    team1, team2 = random_team(assembler), random_team(assembler)
    score1, score2 = random_score(), random_score()
    if not score1:
        score1 = random_score()
    if not score2:
        score2 = random_score()
    return '%s %d - %d %s' % (team1, score1, score2, team2)

def footbot(games=1):
    words = []
    try:
        with codecs.open(CORPUS_FILENAME, encoding='utf-8') as fp:
            words = json.load(fp)
    except IOError:
        sys.stderr.write('File not found: %s\n' % CORPUS_FILENAME)
        sys.stderr.write('Run %s first.\n' % 'build.py')
        return

    corpus = FootbotAssembler(words)

    return ['%s %s #WorldCup #WorldCup2014' % (choice(ICONS), random_game(corpus))
            for _ in range(games)]

def main():
    lines = footbot(10)
    if lines:
        print '\n'.join(lines)
    else:
        return 1

if __name__ == '__main__':
    sys.exit(main())
