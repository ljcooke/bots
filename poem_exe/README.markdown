poem.exe
========

**poem.exe** is a [twitter\_ebooks][twitter-ebooks] bot that generates tiny
haiku-like poems for @[poem\_exe][poem.exe].

The *convert_haiku.py* file reads haiku from a folder of text files and
converts them to a single JSON file which the bot can use.

The *poem.rb* file generates poems using a Queneau assembly process. A poem is
constructed by selecting the first line of a random haiku, the second line of
another, and the third line of yet another.

This forms a 1–2–3 structure. Sometimes a different structure is used: for
example, a 1–2–2–3 structure, in which two middle lines are taken from two
different poems.

[poem.exe]: https://twitter.com/poem_exe
[twitter-ebooks]: https://github.com/mispy/twitter_ebooks
[twitter-ebooks-example]: https://github.com/mispy/ebooks_example/blob/master/bots.rb
