#!/usr/bin/env python
"""
Combine Twitter JSON files for twitter_ebooks.

Usage example:

    ebooks archive user1 archive/user1.json
    ebooks archive user2 archive/user2.json

    ./frankencorpus.py archive/user1.json archive/user2.json -o monster.json

    ebooks consume monster.json
    ebooks gen model/monster.model

"""
import argparse
import codecs
import json
import sys

REPLACEMENTS = (
    # change smart quotes to dumb quotes
    (u'\u2018', "'"),
    (u'\u2019', "'"),
    (u'\u201C', '"'),
    (u'\u201D', '"'),
)

class Corpus:

    def __init__(self, filenames, lower):
        self.indexed_tweets = {}
        self.lower = lower

        for fn in filenames:
            with codecs.open(fn, encoding='utf-8') as fp:
                print('Reading %s' % fn)
                tweets = json.load(fp)
                print('  %d tweets' % len(tweets))
                self.add_tweets(tweets)

    def normalize(self, text):
        if self.lower:
            text = text.lower()
        for pattern, replacement in REPLACEMENTS:
            text = text.replace(pattern, replacement)
        return text

    def add_tweets(self, tweets):
        for tweet in tweets:
            tid = int(tweet['id'])
            assert tid > 0
            assert tid == int(tweet['id_str'])
            if tid not in self.indexed_tweets:
                tweet['text'] = self.normalize(tweet['text'])
                self.indexed_tweets[tid] = tweet

    def write(self, fp):
        json.dump(self.sorted_tweets(), fp, indent=2)

    def sorted_tweets(self):
        keys = tuple(reversed(sorted(self.indexed_tweets.keys())))
        print 'Total: %d tweets' % len(keys)
        return tuple(self.indexed_tweets[k] for k in keys)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('filenames', metavar='USER.json', type=str, nargs='+',
                    help='one or more tweet files in JSON format (required)')
    ap.add_argument('-o', '--outfile', metavar='OUT.json', required=True,
                    help='output filename (required)')
    ap.add_argument('--lower', action='store_true',
                    help='convert tweets to lower case')
    args = ap.parse_args()

    if any(not fn.endswith('.json') for fn in args.filenames):
        sys.stderr.write('Filenames must end with .json\n')
        return 1

    corpus = Corpus(args.filenames, lower=args.lower)
    with codecs.open(args.outfile, 'w', encoding='utf-8') as fp:
        print('Writing to %s' % args.outfile)
        corpus.write(fp)

if __name__ == '__main__':
    sys.exit(main())
