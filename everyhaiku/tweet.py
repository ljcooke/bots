import os

import twitter  # pip install twitter

def post_tweet(text):
    assert len(text) <= 140, 'tweet is too long'
    auth = twitter.OAuth(os.environ['TWITTER_USER_TOKEN'],
                         os.environ['TWITTER_USER_SECRET'],
                         os.environ['TWITTER_API_KEY'],
                         os.environ['TWITTER_API_SECRET'])
    t = twitter.Twitter(auth=auth)
    return t.statuses.update(status=text, trim_user=True)
