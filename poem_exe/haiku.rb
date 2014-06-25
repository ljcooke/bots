require 'json'

HAIKU_FORM = { :pattern => [1, 2, 3], :keep_pauses => true }
ALT_FORMS = [
  { :pattern => [1, 3] },
  { :pattern => [1, 3, 1, 3] },
  { :pattern => [1, 2, 2, 3] },
]

module Haiku
  def self.format_haiku(text, kwargs={})
    poem = text.strip.downcase.gsub /[.]$/, ';'
    # move some words to the preceding line
    poem.gsub! /(\w|,|;)\n(among|in|of|on|that|towards?)\s/, "\\1 \\2\n"
    poem.gsub! /(,|;)\n(i|is)\s/, "\\1 \\2\n"
    # strip punctuation
    poem.gsub! /[;]$/, ''
    poem.gsub! /[;]/, ','
    poem.gsub! /[.,:;]$/, ''
    poem = poem.split("\n").join(' / ') if kwargs[:single_line]
    poem
  end

  class Queneau
    def initialize(corpus_filename)
      @corpus_filename = corpus_filename
      load_corpus
    end

    def load_corpus
      @tweets = JSON.parse(File.read(@corpus_filename), symbolize_names: true)
    end

    def sample
      lines = []
      form = (rand(5) > 0) ? HAIKU_FORM : ALT_FORMS.sample
      tweets = @tweets.sample(form[:pattern].length)
      form[:pattern].each_with_index do |bucket_num, tweet_index|
        bucket = case bucket_num
                 when 1 then :intro
                 when 2 then :middle
                 when 3 then :outro
                 else nil
                 end
        next if bucket.nil?
        line = tweets[tweet_index][bucket].sample
        line = line.gsub(/\u2014|\u2026/, ' ').split.join(' ') unless form[:keep_pauses]
        lines << line unless line.nil?
      end
      lines
    end
  end
end
