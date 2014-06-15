#!/usr/bin/env ruby
#
# Thanks to @negatendo for help and cheat codes
#

require 'json'
require 'twitter_ebooks'

DELAY = 1..40

class ReplyPool
  def initialize
    @replies = Hash.new
  end

  def add(tweet, meta)
    username = tweet[:user][:screen_name].downcase
    @replies[username] = [tweet, meta]
  end

  def take(tweet)
    unless tweet.nil?
      username = tweet[:user][:screen_name].downcase
      reply = @replies.delete(username)
      yield reply unless reply.nil?
    end
  end

  def size
    @replies.size
  end
end

class HorseBot
  def initialize(bot, modelname)
    @bot = bot
    @model = nil
    @model_filename = "model/#{modelname}.model"
    @model_mtime = 0
    @following = []
    @followers = []
    @reply_pool = ReplyPool.new

    config = JSON.parse(File.read('config.json'), symbolize_names: true)
    # app keys
    bot.consumer_key = config[:consumer_key]
    bot.consumer_secret = config[:consumer_secret]
    # oauth keys for the account - try https://github.com/marcel/twurl
    bot.oauth_token = config[:oauth_token]
    bot.oauth_token_secret = config[:oauth_token_secret]

    bot.on_startup do
      load_model :force => true
    end

    bot.scheduler.every '1h' do
      load_model
    end

    bot.on_follow do |user|
      bot.delay DELAY do
        username = user[:screen_name]
        next if @following.include? username
        bot.scheduler.schedule '0s', :mutex => 'replies' do
          bot.follow(username)
          @followers << username
        end
      end
    end

    bot.on_mention do |tweet, meta|
      reply(tweet, meta)
    end

    bot.on_timeline do |tweet, meta|
      text = tweet[:text]
      rt = tweet[:retweeted_status]
      next if rt.nil? and text.start_with?("RT ")
      next unless interesting? text
      bot.log "#{tweet[:user][:screen_name]} said: #{text}"

      if very_interesting? text
        action = reply(tweet, meta)   unless rand > 0.5
        action = retweet(tweet)       unless action or rand > 0.5
        action = favorite(tweet)      unless action
      end
    end

    bot.on_message do |dm|
      # bot.reply(dm, "secret secrets")
    end

    bot.scheduler.every '3m', :first_in => '5s' do
      toot if rand(20) == 0
    end

    bot.scheduler.every '1h', :first_in => '1s', :mutex => 'replies' do
      followers = bot.twitter.followers.map { |x| x[:screen_name].downcase }
      following = bot.twitter.following.map { |x| x[:screen_name].downcase }
      to_follow = (followers - following).sample 10
      to_unfollow = (following - followers).sample 10
      if to_follow.any?
        bot.log "Following #{to_follow}"
        bot.twitter.follow(to_follow)
      end
      if to_unfollow.any?
        bot.log "Unfollowing #{to_unfollow}"
        bot.twitter.unfollow(to_unfollow)  unless to_unfollow.empty?
      end
      @followers = followers
      @following = following - to_unfollow
      bot.log "Followers: #{followers.size}"
    end
  end

  def load_model(kwargs={})
    mtime = File.mtime(@model_filename).to_i
    unless kwargs[:force]
      return if mtime == @model_mtime
    end
    @bot.log "Loading #{@model_filename}"
    @model = Ebooks::Model.load(@model_filename)
    @top100 = @model.keywords.top(100).map(&:to_s).map(&:downcase)
    @top50 = @model.keywords.top(50).map(&:to_s).map(&:downcase)
    @bot.log "Keywords: #{@top100}"
    @bot.log "Testing: #{@model.make_statement 80}"
    @model_mtime = mtime
  end

  def toot
    text = @model.make_statement(140)
    @bot.tweet(text) unless @model.verbatim? text
  end

  def filter_reply_prefix(prefix)
    # TODO - remove @s that aren't in @followers
    prefix
  end

  def reply_now(tweet, meta)
    # this should be called from the scheduler with :mutex => 'replies'
    username = tweet.user[:screen_name]
    if @followers.include? username
      prefix = filter_reply_prefix(meta[:reply_prefix])
      length = 140 - prefix.length
      if prefix.nil? or prefix.strip.empty?
        @bot.log "No-one left to reply to :'("
      elsif length < 40
        @bot.log "Not enough room for an interesting reply"
      elsif rand < 0.05
        @bot.log "Abandoning conversation on a whim"
      else
        text = @model.make_response(tweet[:text], length)
        @bot.reply(tweet, prefix + text) unless @model.verbatim? text
      end
    else
      @bot.log "#{username} not in followers"
      #@bot.twitter.unfollow(username)
    end
  end

  def reply(tweet, meta)
    @bot.log "Scheduling reply to @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.scheduler.schedule '0s', :mutex => 'replies' do
      # add the reply to the pool.
      # this will replace any other pending reply from the same user
      @reply_pool.add tweet, meta
      @bot.log "Replies in pool: #{@reply_pool.size}"
    end
    @bot.delay DELAY do
      @bot.scheduler.schedule '0s', :mutex => 'replies' do
        # remove the tweet from the pool (or whatever tweet may have replaced it)
        @reply_pool.take(tweet) do |tweet, meta|
          reply_now(tweet, meta)
        end
      end
    end
    :reply
  end

  def favorite(tweet)
    @bot.log "Will fav @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.delay DELAY do
      @bot.twitter.favorite tweet[:id]
    end
    :favorite
  end

  def retweet(tweet)
    return false if tweet[:user][:screen_name] == 'inky'
    @bot.log "Will retweet @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.delay DELAY do
      @bot.twitter.retweet tweet[:id]
    end
    :retweet
  end

  def interesting?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase)
    !!(tokens.find { |t| @top100.include? t })
  end

  def very_interesting?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase)
    tokens.select{ |t| @top100.include? t }.uniq.count > 1
  end
end

Ebooks::Bot.new("horse_inky") do |bot|
  # make a bot for @horse_inky using the @inky corpus
  HorseBot.new bot, "inky"
end
