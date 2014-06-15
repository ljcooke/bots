import codecs
import json
import os
import random
import shutil

class WordBank(object):

    def __init__(self, json_filename):
        object.__init__(self)
        self.filename = json_filename
        with codecs.open(json_filename, encoding='utf-8') as fp:
            obj = json.load(fp)
            self.tweeted = obj.get('tweeted', {})
            self.pending = obj.get('pending', [])

    def __getitem__(self, key):
        return self.tweeted.get(key, None)

    def __setitem__(self, key, value):
        self.save_word_tweet(key, value)

    def any_pending_word(self):
        return random.choice(self.pending) if self.pending else None

    def save(self):
        obj = {
            'tweeted': self.tweeted,
            'pending': self.pending,
        }
        tmp_filename = self.filename + '.tmp'
        with codecs.open(tmp_filename, 'w', encoding='utf-8') as fp:
            json.dump(obj, fp)
        if os.stat(tmp_filename).st_size > 0:
            shutil.move(tmp_filename, self.filename)
        else:
            sys.stderr.write('error: nothing saved to %s\n', tmp_filename)

    def save_word_tweet(self, word, tweet):
        assert word in self.pending
        self.tweeted[word] = tweet
        self.pending.remove(word)
        self.save()
