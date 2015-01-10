import argparse
import codecs
import json
import re
import string
import sys
import unicodedata
from itertools import chain
from random import choice, randint, random
from string import ascii_uppercase as UPPERCASE

from queneau import WordAssembler
from tweet import post_tweet

CORPUS_FILENAME = 'corpus.json'

class BotechreAssembler(WordAssembler):

    def __init__(self, corpus=[]):
        super(BotechreAssembler, self).__init__(corpus['tokens'])
        self.title_chance = corpus['title_chance']
        self.camel_chance = corpus['camel_chance']
        self.min_chars = corpus['min_chars']
        self.max_chars = corpus['max_chars']

def random_title(assembler):
    # generate a title (this should be in lowercase)
    title = ''
    for _ in range(10):
        title = assembler.assemble_word()
        if assembler.min_chars <= len(title) <= assembler.max_chars:
            break

    # change some numbers
    title = ''.join(choice(string.digits)
                    if c in string.digits and not randint(0, 1)
                    else c for c in title)

    # convert random characters to uppercase
    words = []
    for word in title.split():
        chars = []
        chars.append(word[0].upper()
                     if random() <= assembler.title_chance
                     else word[0])
        for char in word[1:]:
            if random() <= assembler.camel_chance:
                char = char.upper()
            chars.append(char)
        words.append(''.join(chars))
    title = ' '.join(words)

    # close some brackets
    if word.count('(') == word.count(')') + 1:
        title += ')'
    return title

def botechre(times=1):
    corpus = {}
    try:
        with codecs.open(CORPUS_FILENAME, encoding='utf-8') as fp:
            corpus = json.load(fp)
    except IOError:
        sys.stderr.write('File not found: %s\n' % CORPUS_FILENAME)
        sys.stderr.write('Run %s first.\n' % 'build.py')
        return

    assembler = BotechreAssembler(corpus)
    return [random_title(assembler) for _ in range(times)]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('-t', '--tweet', action='store_true')
    args = ap.parse_args()

    if args.tweet:
        titles = botechre()
        if titles:
            post_tweet(titles[0])
    else:
        lines = botechre(10)
        print('\n'.join(lines))

if __name__ == '__main__':
    sys.exit(main())
