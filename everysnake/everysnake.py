#!/usr/bin/env python
import argparse

from wordbank import WordBank
from tweet import post_tweet

WORDBANK_FILENAME = 'snake.json'

def snake(word):
    return '%s snake' % word

def main_tweet():
    wb = WordBank(WORDBANK_FILENAME)
    word = wb.any_pending_word()
    text = snake(word)
    tweet = post_tweet(text)
    if tweet:
        wb[word] = tweet
    else:
        sys.stderr.write('No tweet saved for "%s"\n' % word)

def main_test():
    wb = WordBank(WORDBANK_FILENAME)
    word = wb.any_pending_word()
    print snake(word) + '\n'
    print 'Words remaining: %d' % len(wb.pending)

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('-t', '--tweet', action='store_true')
    args = ap.parse_args()

    if args.tweet:
        main_tweet()
    else:
        main_test()
