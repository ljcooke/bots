import codecs
import json
import sys
from glob import glob

from footbot import CORPUS_FILENAME

def main():
    words = []

    for fn in glob('data/*.txt'):
        with codecs.open(fn, encoding='utf-8') as fp:
            words.extend(filter(bool, (line.strip().lower() for line in fp)))

    if words:
        with codecs.open(CORPUS_FILENAME, 'w', encoding='utf-8') as fp:
            json.dump(words, fp)
    else:
        sys.stderr.write('Add a .txt file to the data directory '
                         'to get started.\n')
        return 1

if __name__ == '__main__':
    sys.exit(main())
