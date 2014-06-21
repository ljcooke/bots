# coding: utf-8
"""
Convert one or more haiku text files to a JSON list of minimal tweet objects,
each containing a 'text' key.

Haiku in the text file must be separated by an empty line. The # character can
be used to add comments.

"""
import codecs
import json
import re
from glob import glob

INPUT_GLOB = 'haiku/*.txt'
OUTPUT_FILENAME = 'corpus/haiku.json'

REPLACE = (
    # convert smart quotes
    ("'", re.compile(u'\u2018\u2019')),
    ('"', re.compile(u'\u201C\u201D')),

    # remove double quotes
    ('', re.compile('"')),

    # em dash
    (u'\u2014', re.compile(u'--|\u2013|\\B-|-\\B')),
    (u' \u2014 ', re.compile(u'\u2014')),

    # ellipsis
    (u'\u2026', re.compile(r'\.( \.|\.)+')),
    (u'\u2026', re.compile(u'\\b \u2026')),
)

all_haiku = set()

for fn in glob(INPUT_GLOB):
    print 'Reading', fn
    lines = None
    with codecs.open(fn, encoding='utf-8') as fp:
        lines = fp.readlines()

    all_lines = (line.split('#', 1)[0].strip() for line in lines)
    for haiku in '\n'.join(all_lines).split('\n\n'):  # lol
        if 'http://' in haiku or 'https://' in haiku:
            raise ValueError, 'haiku includes a url: %s' % repr(haiku)
        for repl, regex in REPLACE:
            haiku = regex.sub(repl, haiku)
            #for s, r in REPLACE:
                #haiku = haiku.replace(s, r)
        lines = (' '.join(line.split()) for line in haiku.split('\n'))
        lines = tuple(line.lower() for line in lines if line)
        if lines:
            all_haiku.add(lines)

tweets = [{'lines': lines,
           'text': ' / '.join(lines)}
          for lines in all_haiku]

print 'Writing', OUTPUT_FILENAME
with codecs.open(OUTPUT_FILENAME, 'w', encoding='utf-8') as fp:
    json.dump(sorted(tweets), fp, indent=2)

maxlen = max(len(h['text']) for h in tweets)
print 'Wrote {} haiku with maximum length {}'.format(len(all_haiku), maxlen)
