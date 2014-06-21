require 'json'

HAIKU_FORM = { :pattern => [1, 2, 3] }

FORMS = [
  HAIKU_FORM,

  # zip form
  { :pattern => [1, 2, 1, 3], :strip_pauses => true },
  { :pattern => [1, 2, 2, 3], :strip_pauses => true },
]

module Haiku
  def self.format_haiku(text)
    text = text.strip
    text = text.chomp('.') if text.end_with?('.') and text.count('.') == 1
    text.downcase
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
      form = (rand(4) > 0) ? HAIKU_FORM : FORMS.sample
      tweets = @tweets.sample(form[:pattern].length)
      form[:pattern].each_with_index do |line_num, tweet_index|
        line = tweets[tweet_index][:lines][line_num - 1]
        line = line.gsub(/\u2014|\u2026/, ' ').split.join(' ') if form[:strip_pauses]
        lines << line unless line.nil?
      end
      lines
    end
  end
end
