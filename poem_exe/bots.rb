#!/usr/bin/env ruby

require 'json'
require 'twitter_ebooks'  # https://github.com/mispy/twitter_ebooks

require_relative 'poem'

AUTH_FILENAME = 'auth.twitter.json'
TWEET_CHANCE = 0...7
MIN_PASSED_TWEETS = 3
MAX_PASSED_TWEETS = 15

module PoemExe
  class Bot
    def initialize(bot, model_name)
      @bot = bot
      @passed_tweets = 0
      @poet = PoemExe::Poet.new(model_name)

      auth = JSON.parse(File.read(AUTH_FILENAME), symbolize_names: true)
      # app keys
      bot.consumer_key = auth[:consumer_key]
      bot.consumer_secret = auth[:consumer_secret]
      # oauth keys for the account - try https://github.com/marcel/twurl
      bot.oauth_token = auth[:token]
      bot.oauth_token_secret = auth[:token_secret]

      bot.on_startup do
        if ARGV.include?('tweet')
          tweet_poem
        else
          test_haiku = @poet.make_poem(:single_line => true)
          @bot.log "Testing: #{test_haiku.inspect}"
        end
      end

      bot.scheduler.every '11m' do
        if @poet.load_model
          @bot.log "Reloaded #{model_name}"
        end
        can_tweet = (@passed_tweets >= MIN_PASSED_TWEETS)
        should_tweet = (@passed_tweets >= MAX_PASSED_TWEETS or rand(TWEET_CHANCE) == 0)
        if can_tweet and should_tweet
          tweet_poem
          @passed_tweets = 0
        else
          @passed_tweets += 1
          @bot.log("Passed #{@passed_tweets} chances to tweet") if @passed_tweets % 5 == 0
        end
      end
    end

    def tweet_poem
      poem = @poet.make_poem
      @bot.tweet(poem) unless poem.nil? or poem.empty? or poem.length > 140
    end
  end
end

Ebooks::Bot.new("poem_exe") do |bot|
  PoemExe::Bot.new bot, 'haiku'
end
