bots
====

Twitter bots!

footbot
-------

**footbot** generates football scores for @[thematchbot][].

Sample output from *footbot.py*:

    ⚽ Mursillwe 1 - 4 Line
    ⚽ Ponestlety 0 - 0 Dol Touthe
    ⚽ Chaltace 1 - 0 Nembertlad
    ⚽ Lid 3 - 4 Wetts Cemptolsen
    ⚽ Wewsbadentfinty 3 - 1 Wundety
    ⚽ Brust Hocitspuy 2 - 1 Gold
    ⚽ Olotyewnende 2 - 0 Namptilheldars
    ⚽ Wor 0 - 1 Beartlethle
    ⚽ Lotyiwouwn 2 - 3 Seterewn
    ⚽ Onhedime 1 - 2 Cety

### Getting started

You'll need the following:

  * [Python 2][python]
  * The *queneau.py* file from [olipy][]
  * A *data* directory with one or more text files

The text files should have one entry per line. (For example, @[thematchbot][]
uses a single text file with one football team per line.) Run *build.py* once
to read the files in the *data* directory and generate the file *corpus.json*.

Once you've got a *corpus.json* file, run *footbot.py* again and again to get
your football fix.


horsebot
--------

**horsebot** is a [twitter\_ebooks][twitter-ebooks] bot for
@[horse\_inky][horse-inky]. It generates pseudo-Markov nonsense based on a
corpus of tweets by @[inky][].

Work in progress!


[horse-inky]: https://twitter.com/horse_inky
[inky]: https://twitter.com/inky
[thematchbot]: https://twitter.com/thematchbot

[olipy]: https://github.com/leonardr/olipy
[python]: https://www.python.org/downloads/
[twitter-ebooks]: https://github.com/mispy/twitter_ebooks
[twitter-ebooks-example]: https://github.com/mispy/ebooks_example/blob/master/bots.rb
