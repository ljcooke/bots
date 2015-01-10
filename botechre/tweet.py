import twitter

from config import API_KEY, API_SECRET, USER_TOKEN, USER_SECRET

def post_tweet(text):
    assert len(text) <= 140, 'tweet is too long'
    auth = twitter.OAuth(USER_TOKEN, USER_SECRET, API_KEY, API_SECRET)
    t = twitter.Twitter(auth=auth)
    return t.statuses.update(status=text, trim_user=True)
