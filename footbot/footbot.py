import codecs
import json
import sys
from queneau import WordAssembler
from random import choice, randint, random

CORPUS_FILENAME = 'corpus.json'
ICONS = u'\u26BD'

def format_name(string):
    return ' '.join(w.capitalize() for w in string.split())

def random_score():
    return int(random() * random() * 5)

def random_team(assembler):
    team = ''
    for _ in range(10):
        length = randint(3, 9)
        team = assembler.assemble_word(length=length)
        if team and all(len(w) >= 3 for w in team.split()):
            break
    return format_name(team)

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

    corpus = WordAssembler(words)
    return ['%s %s' % (choice(ICONS), random_game(corpus))
            for _ in range(games)]

def main():
    lines = footbot(10)
    if lines:
        print '\n'.join(lines)
    else:
        return 1

if __name__ == '__main__':
    sys.exit(main())
