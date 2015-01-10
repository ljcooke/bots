import codecs
import sys
from datetime import datetime, timedelta
from glob import glob
from random import choice, randint, random

from tweet import post_tweet

PATTERN = "%(time)s %(verb)s %(noun)s %(when)s"
WHENEVER = (
    'every day',
    'every week',
    'every fortnight',
    'whenever',
    'right now',
)

def norm_line(line):
    return line.split('#', 1)[0].strip() if line else ''

def lines_from_file(fp):
    return tuple(s for s in (norm_line(line) for line in fp) if s)

class Weed():

    def __init__(self):
        verbs, nouns = set(), set()

        for fn in glob('verbs/*.txt'):
            with codecs.open(fn, encoding='utf-8') as fp:
                for line in lines_from_file(fp):
                    verbs.add(line)

        for fn in glob('nouns/*.txt'):
            with codecs.open(fn, encoding='utf-8') as fp:
                for line in lines_from_file(fp):
                    nouns.add(line)

        self.verbs = tuple(verbs)
        self.nouns = tuple(nouns)

    def generate(self):
        time, verb, noun, when = None, None, None, None

        # check for the new year
        west_time = datetime.utcnow() - timedelta(8.0 / 24.0)
        east_time = datetime.utcnow() + timedelta(11.0 / 24.0)
        new_year = lambda dt: dt.day == 1 == dt.month
        if new_year(west_time) or new_year(east_time):
            time = east_time.year
            when = choice(('every year', 'every year', 'all year long'))

        strings = {
            'time': time or '%d:20' % randint(1, 12),
            'verb': verb or choice(self.verbs),
            'noun': noun or choice(self.nouns),
            'when': when or ('every day' if random() < 0.95
                             else choice(WHENEVER)),
        }
        return (PATTERN % strings).upper()

def main():
    weed = Weed()
    if 'tweet' in sys.argv:
        post_tweet(weed.generate())
    else:
        for _ in range(10):
            print(weed.generate())

if __name__ == '__main__':
    sys.exit(main())
