import codecs
import json
import sys
from glob import glob

from botechre import CORPUS_FILENAME

def main():
    tokens = []
    total_words, total_chars = 0, 0
    title_words, camel_chars = 0, 0
    min_chars, max_chars = 0, 0

    for fn in glob('data/*.txt'):
        with codecs.open(fn, encoding='utf-8') as fp:
            tokens.extend(filter(bool, (line.split('#', 1)[0].strip() #.lower()
                                        for line in fp)))

    for token in tokens:
        min_chars = min(len(token), min_chars or 999999)
        max_chars = max(len(token), max_chars)
        for word in token.split():
            total_words += 1
            total_chars += len(word)
            if word[0] != word[0].lower():
                title_words += 1
            camel_chars += sum(c != c.lower() for c in word[1:])

    if tokens:
        corpus = {
            'tokens': [t.lower() for t in tokens],
            'title_chance': float(title_words) / float(total_words),
            'camel_chance': float(camel_chars) / float(total_chars),
            'min_chars': min_chars,
            'max_chars': max_chars,
        }
        with codecs.open(CORPUS_FILENAME, 'w', encoding='utf-8') as fp:
            json.dump(corpus, fp)
    else:
        sys.stderr.write('Add a .txt file to the data directory '
                         'to get started.\n')
        return 1

if __name__ == '__main__':
    sys.exit(main())
