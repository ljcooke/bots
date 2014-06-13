import os
import sys

import twitter

from footbot import footbot
from config import APP_NAME, API_KEY, API_SECRET

AUTH_FILENAME = 'auth.token'

def get_auth_token(fn=AUTH_FILENAME):
    return twitter.oauth_dance(APP_NAME,
                               API_KEY,
                               API_SECRET,
                               token_filename=fn)

def read_auth_token_file(fn=AUTH_FILENAME):
    token, secret = None, None
    with open(fn) as fp:
        token = fp.readline().strip()
        secret = fp.readline().strip()
    return token, secret

def tweet_game(fn=AUTH_FILENAME):
    text = footbot()[0]
    if not len(text) < 140:
        sys.stderr.write('Tweet is too long: %s\n' % text)
        return False

    token, secret = read_auth_token_file(fn)
    auth = twitter.OAuth(token, secret, API_KEY, API_SECRET)
    t = twitter.Twitter(auth=auth)
    result = t.statuses.update(status=text)

    #print result
    return result

def main():
    if os.path.exists(AUTH_FILENAME):
        return 0 if tweet_game() else 1
    else:
        return 0 if get_auth_token() else 0

if __name__ == '__main__':
    sys.exit(main())
