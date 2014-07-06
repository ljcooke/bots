require 'json'

HAIKU_FORM = { :pattern => [1, 2, 3], :keep_pauses => true }
ALT_FORMS = [
  { :pattern => [1, 3] },
  { :pattern => [1, 3, 1, 3] },
  { :pattern => [1, 2, 2, 3] },
  { :pattern => [1, 2, 3, 1, 3] },
]

module PoemExe
  def self.format_poem(text, opts={})
    poem = text.strip.downcase.gsub(/\.{2,}/, "\u2026").gsub(/[.]$/, ';')
    # move some words to the preceding line
    unless rand > 0.5
      poem.gsub! /(\w|,|;)\n(among|in|of|on|that|towards?)\s/, "\\1 \\2\n"
      poem.gsub! /(,|;)\n(i|is)\s/, "\\1 \\2\n"
    end
    # strip punctuation
    poem.gsub! /[;]$/, ''
    poem.gsub! /[;]/, ','
    poem.gsub! /[.,:;]$/, ''
    poem = poem.split("\n").join(' / ') if opts[:single_line]
    poem
  end

  class Queneau
    def initialize(corpus_filename)
      @tweets = JSON.parse(File.read(corpus_filename), symbolize_names: true)
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

  class Poet
    def initialize(model_name)
      @model_name = model_name
      @mtime = {}
      @queneau = nil
      load_model :force => true
    end

    def load_model(opts={})
      corpus_filename = "corpus/#{@model_name}.json"
      mtime = File.mtime(corpus_filename)
      if opts[:force] or mtime != @mtime[:corpus]
        @queneau = PoemExe::Queneau.new corpus_filename
        @mtime[:corpus] = mtime
      end
    end

    def make_poem(opts={})
      lines = []
      10.times do
        lines = @queneau.sample.select { |line| line and not line.empty? }
        break if lines and lines.length > 1
      end
      PoemExe.format_poem(lines.join("\n"), opts) if lines and lines.any?
    end
  end
end
