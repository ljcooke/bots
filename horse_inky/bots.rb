#!/usr/bin/env ruby
#
# Thanks to @negatendo for help and cheat codes
#

require 'json'
require 'twitter_ebooks'

require_relative 'inky_glitch'

AUTH_FILENAME = 'auth.json'

class HorseBot
  def initialize(bot, modelname)
    @bot = bot
    @mtime = {}
    @model = nil
    @model_filename = "model/#{modelname}.model"

    auth = JSON.parse(File.read(AUTH_FILENAME), symbolize_names: true)
    # app keys
    bot.consumer_key = auth[:consumer_key]
    bot.consumer_secret = auth[:consumer_secret]
    # oauth keys for the account - try https://github.com/marcel/twurl
    bot.oauth_token = auth[:oauth_token]
    bot.oauth_token_secret = auth[:oauth_token_secret]

    bot.on_startup do
      load_model :force => true
      toot if ARGV.include? 'tweet'
    end

    bot.scheduler.every '1h' do
      load_model
    end

    bot.scheduler.every '3m' do
      toot if rand(40) == 0
    end
  end

  def log(message)
    @bot.log "[#{Time.now}] #{message}"
  end

  def load_model(kwargs={})
    mtime = File.mtime(@model_filename).to_i
    if kwargs[:force] or mtime != @mtime[:model]
      log "Loading #{@model_filename}"
      @model = Ebooks::Model.load(@model_filename)
      log "Testing: #{glitch(@model.make_statement 80)}"
      @mtime[:model] = mtime
    end
  end

  def toot
    text = nil
    raw_text = nil
    10.times do
      log("Too long; trying another tweet") unless text.nil?
      tweet_len = 130 #hashtags ? 130 - hashtags.length : 130
      2.times do
        text = @model.make_statement tweet_len
        raw_text = text
      end
      text = glitch text
      if text.length <= 140
        @bot.tweet(text) unless @model.verbatim? raw_text
        break
      end
    end
  end

  def glitch(text)
    log "Before glitch: #{text}"
    glitched = HorseInky::transform(text)
    log "After glitch: #{glitched}"
    glitched
  end
end

Ebooks::Bot.new("horse_inky") do |bot|
  # make a bot for @horse_inky using the @inky corpus
  HorseBot.new bot, "inky-merged"
end
