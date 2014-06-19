#!/usr/bin/env ruby
#
# Thanks to @negatendo for help and cheat codes
#

require 'json'
require 'twitter_ebooks'

require_relative 'inky_glitch'

AUTH_FILENAME = 'auth.json'
CONFIG_FILENAME = 'config.json'

DELAY = 1..20
ADMIN_USERNAME = 'inky'

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
    @mtime = {}
    @following = []
    @followers = []
    @reply_pool = ReplyPool.new

    @config = nil
    @boring_keywords = []
    @always_follow = []
    @hashtags = []

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
      load_config :force => true
      load_model :force => true
    end

    bot.scheduler.every '1h' do
      load_config
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
      #next unless interesting? text
      next unless very_interesting? text
      bot.log "#{tweet[:user][:screen_name]} said: #{text}"

      will_rt = retweet(tweet)          unless rand > 0.3
      will_fav = favorite(tweet)        unless will_rt
      will_reply = reply(tweet, meta)   unless rand > 0.3
    end

    bot.on_message do |dm|
      next unless ADMIN_USERNAME and dm[:sender][:screen_name] == ADMIN_USERNAME
      tokens = dm[:text].split
      cmd = tokens[0].to_sym
      if cmd == :tweet
        toot
      #elsif cmd == :delete
      #  tweet_id = tokens[1].to_i
      #  bot.twitter.destroy_status(tweet_id) if tweet_id > 0
      elsif cmd == :reload
        load_config :verbose => true
        load_model :verbose => true
      elsif cmd == :ping
        bot.reply(dm, 'pong')
      else
        bot.log "Unrecognised command: #{cmd}"
      end
    end

    bot.scheduler.every '3m', :first_in => '5s' do
      toot if rand(20) == 0
    end

    bot.scheduler.every '1h', :first_in => '1s', :mutex => 'replies' do
      followers = bot.twitter.followers.map { |x| x[:screen_name].downcase }
      followers |= @always_follow
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
      bot.log("Followers: #{followers.size}") unless followers.size == @followers.size
      @followers = followers
      @following = following - to_unfollow
    end
  end

  def load_config(kwargs={})
    mtime = File.mtime(CONFIG_FILENAME).to_i
    return unless kwargs[:force] or mtime != @mtime[:config]
    @bot.log "Loading #{CONFIG_FILENAME}"
    @config = JSON.parse(File.read(CONFIG_FILENAME), symbolize_names: true)
    @boring_keywords = @config[:boring_keywords].map(&:to_s).map(&:downcase)
    @always_follow = @config[:always_follow].map(&:to_s).map(&:downcase)
    @hashtags = @config[:hashtags].map(&:to_s)
    @mtime[:config] = mtime
  end

  def load_model(kwargs={})
    mtime = File.mtime(@model_filename).to_i
    if kwargs[:force] or mtime != @mtime[:model]
      @bot.log "Loading #{@model_filename}"
      @model = Ebooks::Model.load(@model_filename)
      @top100 = @model.keywords.top(100).map(&:to_s).map(&:downcase).uniq
      @top50 = @model.keywords.top(50).map(&:to_s).map(&:downcase).uniq
      @bot.log "Keywords: #{@top100}"
      @bot.log "Testing: #{glitch(@model.make_statement 80)}"
      @mtime[:model] = mtime
    else
      #@bot.log("File is unchanged: #{@model_filename}") if kwargs[:verbose]
    end
  end

  def toot
    text = nil
    while text.nil? or text.length > 140
      @bot.log("Too long; trying another tweet") unless text.nil?
      hashtags = @hashtags.sample.split.map{|h| " #" + h}.join unless rand > 0.1
      tweet_len = hashtags ? 130 : (130 - hashtags.length)
      2.times do
        text = @model.make_statement tweet_len
        break unless boring? text
        @bot.log "Boring: #{text}"
      end
      text = glitch text
      text += hashtags if hashtags
    end
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
        text = @model.make_response(tweet[:text], length) if boring? text
        text = glitch text
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
    true
  end

  def favorite(tweet)
    @bot.log "Will fav @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.delay DELAY do
      @bot.twitter.favorite tweet[:id]
    end
    true
  end

  def retweet(tweet)
    return if tweet[:user][:screen_name] == ADMIN_USERNAME
    @bot.log "Will retweet @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.delay DELAY do
      @bot.twitter.retweet tweet[:id]
    end
    true
  end

  def boring?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase.gsub "\u2019", "'")
    !!(tokens.find { |t| @boring_keywords.include? t })
  end

  def interesting?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase.gsub "\u2019", "'")
    !!(tokens.find { |t| @top100.include? t })
  end

  def very_interesting?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase.gsub "\u2019", "'")
    tokens.select{ |t| @top100.include? t }.uniq.count > 1
  end

  def glitch(text)
    HorseInky::glitch text
  end
end

Ebooks::Bot.new("horse_inky") do |bot|
  # make a bot for @horse_inky using the @inky corpus
  HorseBot.new bot, "inky-merged"
end
