footbot
=======

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

Getting started
---------------

You'll need the following:

  * [Python 2][python]
  * The *queneau.py* file from [olipy][]
  * A *data* directory with one or more text files

The text files should have one entry per line. (For example, @[thematchbot][]
uses a single text file with one football team per line.) Run *build.py* once
to read the files in the *data* directory and generate the file *corpus.json*.

Once you've got a *corpus.json* file, run *footbot.py* again and again to get
your football fix.


[thematchbot]: https://twitter.com/thematchbot
[python]: https://www.python.org/downloads/
[olipy]: https://github.com/leonardr/olipy
