#!/usr/bin/env ruby

require 'json'
require 'twitter_ebooks'  # https://github.com/mispy/twitter_ebooks

require_relative 'haiku'

AUTH_FILENAME = 'auth.json'
MAX_LENGTH = 90
MAX_LINE_LENGTH = 25
TWEET_CHANCE = 0...7
MAX_PASSED_TWEETS = 10

module Haiku
  class Bot
    def initialize(bot, model_name)
      @bot = bot
      @mtime = {}
      @model_name = model_name
      @model = nil
      @queneau = nil
      @top100 = nil
      @passed_tweets = 0

      auth = JSON.parse(File.read(AUTH_FILENAME), symbolize_names: true)
      # app keys
      bot.consumer_key = auth[:consumer_key]
      bot.consumer_secret = auth[:consumer_secret]
      # oauth keys for the account - try https://github.com/marcel/twurl
      bot.oauth_token = auth[:oauth_token]
      bot.oauth_token_secret = auth[:oauth_token_secret]

      bot.on_startup do
        load_model :force => true
        if ARGV.include?('tweet') or rand(TWEET_CHANCE) == 0
          tweet_haiku
        else
          test_haiku = [Haiku::format_haiku(make_haiku(), :single_line => true)]
          @bot.log "Testing: #{test_haiku}"
        end
      end

      bot.scheduler.every '1h', :first_in => '1m' do
        load_model :force => false
      end

      bot.scheduler.every '11m' do
        if @passed_tweets >= MAX_PASSED_TWEETS or rand(TWEET_CHANCE) == 0
          tweet_haiku
          @passed_tweets = 0
        else
          @passed_tweets += 1
          @bot.log("Passed #{@passed_tweets} chances to tweet") if @passed_tweets % 3 == 0
        end
      end
    end

    def load_model(kwargs={})
      corpus_filename = "corpus/#{@model_name}.json"
      mtime = File.mtime(corpus_filename)
      if kwargs[:force] or mtime != @mtime[:corpus]
        @bot.log "Loading #{corpus_filename}"
        if @queneau.nil?
          @queneau = Haiku::Queneau.new corpus_filename
        else
          @queneau.load_corpus
        end
        @mtime[:corpus] = mtime
      end

      model_filename = "model/#{@model_name}.model"
      mtime = File.mtime(model_filename)
      if kwargs[:force] or mtime != @mtime[:model]
        @bot.log "Loading #{model_filename}"
        @model = Ebooks::Model.load model_filename
        @top100 = @model.keywords.top(100).map(&:to_s).map(&:downcase).uniq
        @bot.log "Top 100 keywords: #{@top100}"
        @mtime[:model] = mtime
      end
    end

    def make_haiku
      lines = []
      10.times do
        method = [:queneau, :queneau, :ebooks].sample
        lines = []
        if method == :queneau
          lines = @queneau.sample
          @bot.log "Queneau haiku: #{lines}"
        elsif method == :ebooks
          text = @model.make_statement MAX_LENGTH
          next if text.empty? or @model.verbatim? text
          lines = text.split('/').map(&:strip)
          if lines.select{ |s| s.length > MAX_LINE_LENGTH }.any?
            @bot.log "Ebooks haiku lines too long: #{lines}"
            lines = nil
            next
          end
          @bot.log "Ebooks haiku: #{lines}"
        end
        lines.select! { |line| line and not line.empty? }
        break if lines and lines.length > 1
      end
      lines.join("\n") if lines and lines.any?
    end

    def tweet_haiku
      text = make_haiku
      unless text.nil? or text.empty? or text.length > 140
        @bot.tweet Haiku::format_haiku(text)
      end
    end
  end
end

Ebooks::Bot.new('twitter_username') do |bot|
  Haiku::Bot.new bot, 'haiku'
end
