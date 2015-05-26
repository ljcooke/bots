import os
import sqlite3

import twitter  # pip install twitter


def post_tweet(text):
    if len(text) > 140:
        raise ValueError('tweet is too long')
    auth = twitter.OAuth(os.environ['TWITTER_USER_TOKEN'],
                         os.environ['TWITTER_USER_SECRET'],
                         os.environ['TWITTER_CONSUMER_KEY'],
                         os.environ['TWITTER_CONSUMER_SECRET'])
    t = twitter.Twitter(auth=auth)
    return t.statuses.update(status=text, trim_user=True)


class DB(object):

    def __init__(self, filename, autocommit=False):
        super(DB, self).__init__()

        self.conn = sqlite3.connect(filename)

        if not autocommit:
            self.conn.isolation_level = None

    def cursor(self):
        return self.conn.cursor()

    def __del__(self):
        self.conn.close()
