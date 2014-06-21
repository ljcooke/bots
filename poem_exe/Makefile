.PHONY: corpus

corpus:
	mkdir -p corpus model
	python convert_haiku.py
	ebooks consume corpus/haiku.json
	ruby test_corpus.rb
