#!/usr/bin/env ruby
#------------------------------------------------------------------------------
# poem.exe
# --------
# author:   Liam Cooke
# live:     2014-06-21 01:47 +01:00
# twitter:  twitter.com/poem_exe
# tumblr:   poemexe.tumblr.com
# license:  MIT License
#------------------------------------------------------------------------------

require 'json'
require 'optparse'


#
# poem.exe generates poems using an approach based on Leonard Richardson's
# Queneau Assembly technique. Each verse in the corpus is divided into three
# "buckets", consisting of one opening line, zero or more middle lines, and one
# closing line.
#
# The generator selects one of the patterns below, which determines the number
# of source poems and which bucket each line will be selected from. For the
# pattern [1, 2, 2, 3], a poem would be generated as follows:
#
#   1. Randomly select four poems from the corpus.
#   2. From the first poem, select the opening line (1).
#   3. From the second poem, randomly select a middle line (2), if any.
#   4. From the third poem, randomly select a middle line (2), if any.
#   5. From the fourth poem, select the closing line (3).
#   6. Put them all together, giving a poem 2-4 lines long.
#

HAIKU_FORM = { :pattern => [1, 2, 3], :keep_pauses => true }

ALT_FORMS = [
  { :pattern => [1, 3] },
  { :pattern => [1, 3, 1, 3] },
  { :pattern => [1, 2, 2, 3] },
]

#
# Poems may be accepted or rejected if they contain any seasonal reference
# keywords. These are mostly based on the Japanese kigo (words or phrases
# associated with particular seasons in Japan).
#
# As poem.exe has readers in both hemispheres, the "seasons" have been
# simplified to two: summer-winter and autumn-spring.
#
# Seasonal references are categorised as either STRONG or WEAK. STRONG
# references are mutually exclusive; WEAK references may overlap. A poem may be
# accepted or rejected based on any STRONG references it contains; if there are
# none, the poem will be accepted if it contains a relevant WEAK reference.
#
# For example, "winter" is a STRONG reference. A poem containing the word
# "winter" would be rejected in autumn-spring; in summer-winter it would be
# accepted unless the poem also contained a STRONG reference to autumn-spring.
#

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
  /\b(hallowe.?en|thanksgiving|trick.or.treat)/,
  nil,
  /\b(christmas|end.of.(the.)?year|presents|santa|sleigh)/,
]

SEASON_WEAK_MATCH = [
  # summer-winter
  %r{
    \b(bath|beach|bicycle|bike|cicada|cycl|cuckoo|field|
       heat|hot|ice.?cream|iris|jellyfish|lilac|lotus|
       meadow|mosquito|naked|nap|nud[ei]|orange|rain|
       siesta|smog|snake|sun|surf|sweat|swim|waterfall|
       grasshopper|fireworks|kimono)
    |
    \b(chill|cold|fallen.*lea[fv]|freez|frost|ic[eyi]|
       night|oyster|smog|snow|white)
  }x,

  # autumn-spring
  %r{
    \b(age|apple|brown|death|die|evergreen|
       fall\b|grape|gr[ea]y|harvest|insect|iris|
       lea[fv]|melanchol|mellow|moon|night|old|peach|
       pear|persimmon|ripe|scarecrow|school|sorrow|
       thunder|typhoon|dragonfl[yi])
    |
    \b(cherry.blossom|flower|frog|haz[ey]|heather|
       lark|lilac|mist|nightingale|peach|popp[yi]|
       sunflower|sweet|warbler|warm|wildflower|
       breeze|stream|butterfl[yi])
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
  /\b(october|
      afraid|bone|cemetery|cobweb|fog|fright|ghost|grave|grim|hallowe|haunt|headstone|
      pumpkin|scare|scream|skelet|skull|spider|spine|spook|tomb|witch|wizard)/x,
  /\b(november|thanksgiving)/,
  /\b(december|bells|carol|festive|gift|jingl|joll|joy|merry|solsti[ct]|tree|twinkl)/,
]

#
# With the bulk of the corpus consisting of haiku by Kobayashi Issa, poem.exe
# quickly developed its own particular fondness for snails (an early classic:
# "snail / between my hands / snail"). Here we give the word a little extra
# weight, for the fans.
#

ALWAYS_IN_SEASON = /snail/


module PoemExe
  def self.format_poem(text, opts={})
    poem = text.strip.downcase.gsub(/\.{2,}/, "\u2026").gsub(/[.]$/, ';')
    # move some words to the preceding line
#    unless rand > 0.5
#      poem.gsub! /(\w|,|;)\n(among|in|of|on|that|towards?)\s/, "\\1 \\2\n"
#      poem.gsub! /(,|;)\n(i|is)\s/, "\\1 \\2\n"
#    end
    # strip punctuation
    poem.gsub! /[;]$/, ''
    poem.gsub! /[;]/, ','
    poem.gsub! /[.,:;\u2014]$/, ''
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
                 when 1 then :a
                 when 2 then :b
                 when 3 then :c
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
      strong = ALWAYS_IN_SEASON.match(text)

      # check some tricky STRONG references
      if /\b(new.?year|first.day.*year)/.match(text)
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

      # no references at all; small chance to keep it
      rand(6) == 0
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

        lines = lines.map { |line|
          line.gsub(/\{.*?\}/) { |choices| choices[1...-1].split(',').sample }
        }

        if lines and lines.any?

          # repeat the first line sometimes
          if lines.count > 2 and rand <= 0.05
            if lines.count == 3 and rand <= 0.3
              lines.insert 2, lines[0]
            else
              lines << lines[0]
            end
          end

          poem = PoemExe.format_poem(lines.join("\n"), opts)
          return poem if timely?(poem, month)
        end

      end
      return poem
    end
  end
end


#
# Command-line usage example:
#
#     ./poem.rb -n3
#         Generate three poems.
#

if __FILE__ == $0
  num_poems = 1

  parser = OptionParser.new do |opts|
    opts.banner = "Usage: poem.rb [-n NUM]"
    opts.on('-n=NUM', 'number of poems to generate') do |n|
      num_poems = [n.to_i, 1].max
    end
  end
  parser.parse!

  poem_exe = PoemExe::Poet.new 'haiku'
  poems = num_poems.times.map { poem_exe.make_poem }
  puts poems.join "\n\n"
end
