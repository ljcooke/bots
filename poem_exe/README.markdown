poem.exe
========

**poem.exe** is a [twitter\_ebooks][twitter-ebooks] bot that generates tiny
haiku-like poems for @[poem\_exe][poem.exe].

The *convert_haiku.py* file reads haiku from a folder of text files and
converts them to a single JSON file which the bot can use.

To generate a poem, the bot randomly selects one of two processes:

  * twitter\_ebooks: A poem is constructed using a pseudo-Markov process. The
    number of lines is unpredictable.

  * Queneau assembly: A poem is constructed by selecting the first line of a
    random haiku, the second line of another, and the third line of yet
    another.

    This forms a 1–2–3 structure. Sometimes a different structure is used such
    as 1–2–1–3, where the first line of another random poem is inserted before
    the final line in the constructed poem.


[poem.exe]: https://twitter.com/poem_exe
[twitter-ebooks]: https://github.com/mispy/twitter_ebooks
[twitter-ebooks-example]: https://github.com/mispy/ebooks_example/blob/master/bots.rb
