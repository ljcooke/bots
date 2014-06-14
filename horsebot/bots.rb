#!/usr/bin/env ruby
#
# Thanks to @negatendo for help and cheat codes
#

require 'json'
require 'twitter_ebooks'

class ReplyPool
  def initialize
    @replies = Hash.new
  end

  def add(tweet, meta)
    username = tweet.user[:screen_name]
    @replies[username] = [tweet, meta]
  end

  def delete_any
    username = @replies.keys.sample
    unless username.nil?
      reply = @replies.delete(username)
      yield reply  unless reply.nil?
    end
  end
end

class HorseBot
  def initialize(bot, modelname)
    @bot = bot
    @model = nil
    @reply_pool = ReplyPool.new

    bot.on_startup do
      config = JSON.parse(File.read('config.json'), symbolize_names: true)

      # app keys
      bot.consumer_key = config[:consumer_key]
      bot.consumer_secret = config[:consumer_secret]
      # oauth keys for the account
      bot.oauth_token = config[:oauth_token]
      bot.oauth_token_secret = config[:oauth_token_secret]

      @model = Ebooks::Model.load("model/#{modelname}.model")
      bot.log "Testing: #{@model.make_statement 80}"
    end

    bot.on_message do |dm|
      # bot.reply(dm, "secret secrets")
    end

    bot.on_follow do |user|
      # follow user back after a delay
      delay = (rand * 60).to_i.to_s + 's'
      bot.log "Will follow #{user[:screen_name]} in #{delay}"
      bot.scheduler.schedule(delay) do
        bot.follow user[:screen_name]
      end
    end

    bot.on_mention do |tweet, meta|
      # add mention to the reply pool, to be replied to later
      bot.scheduler.schedule '0s', :mutex => 'replies' do
        bot.log "Scheduling reply for #{tweet.user[:screen_name]}"
        @reply_pool.add tweet, meta
      end
    end

    bot.on_timeline do |tweet, meta|
      # bot.reply(tweet, meta[:reply_prefix] + "nice tweet")
    end

    bot.scheduler.every '80s', :mutex => 'replies' do
      # reply to a random mention
      @reply_pool.delete_any do |tweet, meta|
        prefix = meta[:reply_prefix]
        length = 140 - prefix.length
        if length > 50
          text = @model.make_response(tweet[:text], length)
          bot.reply(tweet, prefix + text)
        else
          bot.log "Skipping reply for #{prefix}"
        end
      end
    end

    bot.scheduler.every '3m' do
      # tweet something
      if rand(9) == 0
        bot.tweet(@model.make_statement(140))
      end
    end
  end
end

Ebooks::Bot.new("horse_inky") do |bot|
  # make a bot for @horse_inky using the @inky corpus
  HorseBot.new bot, "inky"
end
