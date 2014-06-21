everysnake
==========

**everysnake** posts random words for @[everysnake][].
Inspired by @[everyword][] and @[butt\_things][butt-things].

It consists of three small Python modules:

  * *everysnake.py* is an application to tweet random words from a list,
    appending the word 'snake'. It uses the WordBank class below to select
    random words and keep track of which words have been tweeted.

  * *tweet.py* contains a single method for posting a tweet
    using the Python [twitter][python-twitter] package.
    It reads OAuth keys from *config.py* (see *config.example.py*).

  * *wordbank.py* contains a WordBank class which manages words in a JSON
    file. Initially the file must contain a 'pending' word list. For example:

        {
          "pending": [
            "hello",
            "world"
          ]
        }

    WordBank allows you to select a random word, and to store a tweet response
    for a word. When a tweet is stored, the word is moved to a separate
    'tweeted' dictionary, mapping words to tweets like so:

        {
          "pending": [
            "world"
          ],
          "tweeted": {
            "hello": { ...tweet data here... }
          }
        }

    When a tweet is saved, the changes are written to the JSON file.


[everysnake]: https://twitter.com/everysnake
[everyword]: https://twitter.com/everyword
[butt-things]: https://twitter.com/butt_things
[python-twitter]: https://pypi.python.org/pypi/twitter
