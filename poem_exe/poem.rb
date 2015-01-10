require 'json'

#------------------------------------------------------------------------------
# POETIC FORMS
#------------------------------------------------------------------------------

HAIKU_FORM = { :pattern => [1, 2, 3], :keep_pauses => true }

ALT_FORMS = [
  { :pattern => [1, 3] },
  { :pattern => [1, 3, 1, 3] },
  { :pattern => [1, 2, 2, 3] },
]

#------------------------------------------------------------------------------
# TEMPORAL TESTS
#
# Poems may be accepted or rejected based on which seasonal references they
# contain, if any. These are mostly based on the Japanese kigo (words or
# phrases associated with particular seasons in Japan).
#
# The seasons have been reduced to two: summer-winter and autumn-spring.
#
# Seasonal references are categorised as either STRONG or WEAK. STRONG
# references are mutually exclusive; WEAK references may overlap. A poem may be
# accepted or rejected based on any STRONG references it contains; if there are
# none, the poem will be accepted if it contains a relevant WEAK reference.
#
# For example, "winter" is a STRONG reference. A poem containing the word
# "winter" would be rejected in autumn-spring; in summer-winter it would be
# accepted unless the poem also contained a STRONG reference to autumn-spring.
#------------------------------------------------------------------------------

SEASON_STRONG_MATCH = [
  /summer|winte?r|solsti[ct]/,
  /autumn|spring|equino[xc]/,
]

MONTH_STRONG_MATCH = [
  nil,
  /\b(valentine)/,
  /\b(shamrock)/,
  nil,
  nil,
  nil,
  nil,
  nil,
  nil,
  nil,
  nil,
  /\b(christmas|end.of.(the.)?year|presents|santa|sleigh)/,
]

SEASON_WEAK_MATCH = [
  # summer-winter
  %r{
    \b(bath|beach|bicycle|bike|cicada|cycl|cuckoo|field|
       heat|hot|ice.?cream|iris|jellyfish|lilac|lotus|
       meadow|mosquito|naked|nap|nud[ei]|orange|rain|
       siesta|smog|snake|sun|surf|sweat|swim|waterfall)
    |
    \b(chill|cold|fallen.*lea[fv]|freez|frost|ic[eyi]|
       night|orchid|oyster|smog|snow|white)
  }x,

  # autumn-spring
  %r{
    \b(age|apple|brown|cricket|death|die|evergreen|
       fall\b|grape|gr[ea]y|harvest|insect|iris|
       lea[fv]|melanchol|mellow|moon|night|old|peach|
       pear|persimmon|ripe|scarecrow|school|sorrow|
       thunder|typhoon)
    |
    \b(blossom|cherr[yi]|flower|frog|haz[ey]|heather|
       lark|lilac|mist|nightingale|peach|popp[yi]|
       sunflower|sweet|warbler|warm|wildflower)
  }x,
]

MONTH_WEAK_MATCH = [
  /\b(january|first)/,
  /\b(february|cupid|heart|love)/,
  /\b(march|equino[xc])/,
  /\b(april)/,
  /\b(may)/,
  /\b(june|solsti[ct])/,
  /\b(july)/,
  /\b(august)/,
  /\b(september|equino[xc])/,
  /\b(october|hallowe.?en|pumpkin|thanksgiving)/,
  /\b(november|thanksgiving)/,
  /\b(december|bells|carol|festive|jingl|joll|joy|merry|solsti[ct]|tree|twinkl)/,
]

#------------------------------------------------------------------------------
# Poem generator
#------------------------------------------------------------------------------

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
        unless line.nil?
          line = line.gsub(/\u2014|\u2026/, ' ').split.join(' ') unless form[:keep_pauses]
          lines << line
        end
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

    def timely?(poem, month)
      text = poem.downcase
      strong = false

      # check some tricky STRONG references
      if /\bnew.?year/.match(text)
        return false unless [1, 12].include? month
        strong = true
      end

      # check for STRONG month references
      MONTH_STRONG_MATCH.each_with_index do |pattern, i|
        if pattern && pattern.match(text)
          return false if i != month - 1
          strong = true
        end
      end

      # check for STRONG seasonal references
      season = ((month + 1) / 3) % 2
      SEASON_STRONG_MATCH.each_with_index do |pattern, i|
        if pattern && pattern.match(text)
          return false if i != season
          strong = true
        end
      end

      # all negative tests passed; return if there was a STRONG reference
      return true if strong

      # check for WEAK month references
      return true if MONTH_WEAK_MATCH[month - 1].match(text)

      # check for WEAK seasonal references
      return true if SEASON_WEAK_MATCH[season].match(text)

      # no references at all; let's flip a coin
      [true, false].sample
    end

    def make_poem(opts={})
      month = opts[:month] || Time.now.month
      poem = ''
      100.times do |i|
        lines = []
        10.times do
          lines = @queneau.sample.select { |line| line and not line.empty? }
          break if lines and lines.length > 1
        end
        poem = PoemExe.format_poem(lines.join("\n"), opts) if lines and lines.any?
        return poem if timely?(poem, month)
      end
      return poem
    end
  end
end
