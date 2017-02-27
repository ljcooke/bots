#!/usr/bin/env python2.7
# coding: utf-8
"""
Convert one or more haiku text files to a JSON list of minimal tweet objects,
each containing a 'text' key.

Haiku in the text file must be separated by an empty line. The # character can
be used to add comments.

"""
import argparse
import codecs
import json
import os
import re
import sys
from glob import glob

INPUT_GLOB = 'haiku/*.txt'
OUTPUT_FILENAME = 'corpus/haiku.json'

RE_CONTAINS_URL = re.compile('https?://')
RE_WEAK_LINE = re.compile(' (and|by|from|is|of|that|the|with)\\n',
                          flags=re.IGNORECASE)

REPLACE = (
    # convert smart quotes
    (re.compile(u'\u2018|\u2019'), "'"),
    (re.compile(u'\u201C|\u201D'), '"'),

    # remove double quotes
    (re.compile('"'), ''),

    # em dash
    (re.compile(u'--|\u2013|\\B-|-\\B|~'), u'\u2014'),
    (re.compile(u'\u2014'), u' \u2014'),

    # ellipsis
    (re.compile(r'\.( \.|\.)+'), u'\u2026'),
    (re.compile(u'\\b \u2026'), u'\u2026'),
)

output_haiku = []
output_texts = []

def parse_credit(line):
    line = line.strip()
    return line[2:].lstrip() if line.startswith('//') else None

def convert_dirs(dirs):

    for dirname in dirs:
        for fn in glob(os.path.join(dirname, '*.txt')):
            print 'Reading', fn
            input_lines = None
            with codecs.open(fn, encoding='utf-8') as fp:
                input_lines = fp.readlines()

            # find a credit line for the file, if one exists
            file_credit = parse_credit(input_lines[0])
            if file_credit:
                input_lines.pop(0)

            # strip trailing whitespace and comments
            input_lines = (line.split('#', 1)[0].strip()
                        for line in input_lines
                        if not line.lstrip().startswith('#'))

            # select all unique haiku, joining adjacent lines to form haiku strings
            unique_haiku = set()
            for haiku in '\n'.join(input_lines).split('\n\n'):
                haiku = haiku.strip().lower()
                if RE_CONTAINS_URL.search(haiku):
                    raise ValueError, 'haiku includes a url: %s' % repr(haiku)
                elif RE_WEAK_LINE.search(haiku):
                    raise ValueError, 'haiku contains a weak line: %s' % repr(haiku)
                for regex, repl in REPLACE:
                    haiku = regex.sub(repl, haiku)
                if haiku:
                    unique_haiku.add(haiku)
            print '    %d unique haiku' % len(unique_haiku)

            # separate the lines into first, middle, and last buckets
            for haiku in unique_haiku:
                haiku_lines = haiku.split('\n')
                credit = file_credit
                line_count = len(haiku_lines)
                output_lines = []
                buckets = [[], [], []]
                for i, line in enumerate(haiku_lines):
                    bucket = 0 if i == 0 else (2 if i == line_count - 1 else 1)
                    tokens = line.split()
                    if not tokens:
                        continue
                    line = ' '.join(tokens)
                    output_lines.append(line)
                    buckets[bucket].append(line)
                if output_lines:
                    obj = {
                        #'text': ' / '.join(output_lines),
                        #'lines': tuple(output_lines),
                        'a': tuple(buckets[0]),
                        'b': tuple(buckets[1]),
                        'c': tuple(buckets[2]),
                    }
                    if credit:
                        obj['source'] = credit
                    output_haiku.append(obj)
                    output_texts.append(' / '.join(output_lines))

    print 'Writing', OUTPUT_FILENAME
    with codecs.open(OUTPUT_FILENAME, 'w', encoding='utf-8') as fp:
        json.dump(sorted(output_haiku), fp, indent=2, sort_keys=True, ensure_ascii=False)

    maxlen = max(len(text) for text in output_texts)
    print 'Wrote {} haiku with maximum length {}'.format(len(output_haiku), maxlen)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('srcdir', nargs='*')
    args = parser.parse_args()

    if not args.srcdir:
        parser.print_help()
        return 1

    convert_dirs(args.srcdir)

if __name__ == '__main__':
    sys.exit(main())
