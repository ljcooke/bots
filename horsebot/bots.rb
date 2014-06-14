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

    bot.on_message do |dm|
      # bot.reply(dm, "secret secrets")
    end

    bot.on_follow do |user|
      # follow user back after a delay
      delay = (rand * 60).to_i.to_s + 's'
      username = user[:screen_name].downcase
      next if @following.include? username
      bot.log "Will follow #{username} in #{delay}"
      bot.scheduler.schedule delay, :mutex => 'replies' do
        bot.follow username
        @followers << username
      end
    end

    bot.on_mention do |tweet, meta|
      # add mention to the reply pool, to be replied to later
      bot.scheduler.schedule '0s', :mutex => 'replies' do
        username = tweet.user[:screen_name]
        bot.log "Scheduling reply to #{username} (from mentions)"
        @reply_pool.add tweet, meta
      end
    end

    bot.on_timeline do |tweet, meta|
      text = tweet[:text]
      username = tweet[:user].screen_name.downcase
      next if tweet[:retweeted_status] or tweet[:text].start_with?("RT")
      next unless interesting? text

      bot.log "#{username} said: #{text}"
      if very_interesting? text
        bot.twitter.favorite(tweet[:id])
        bot.log "Fav'd #{username}!"
      end

      next unless rand < 0.1
      bot.scheduler.schedule '0s', :mutex => 'follow' do
        bot.log "Scheduling reply to #{username} (from timeline)"
        respond(tweet, meta)
      end
    end

    bot.scheduler.every '80s', :mutex => 'replies' do
      # reply to a random mention or tweet of interest
      @reply_pool.delete_any do |tweet, meta|
        respond(tweet, meta)
      end
    end

    bot.scheduler.every '3m', :first_in => '5s' do
      # tweet something
      if rand(9) == 0
        toot
      end
    end

    bot.scheduler.every '3h', :first_in => '1s', :mutex => 'replies' do
      followers = bot.twitter.followers.map { |x| x[:screen_name].downcase }
      following = bot.twitter.following.map { |x| x[:screen_name].downcase }
      to_follow = followers - following
      to_unfollow = following - followers
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

    bot.scheduler.every '1h' do
      load_model
    end

    bot.scheduler.schedule '1s' do
      bot.log ["Beep boop", "Blerp blerp"].sample
      #toot
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
    @bot.tweet @model.make_statement(140)
  end

  def filter_reply_prefix(prefix)
    # TODO - remove @s that aren't in @followers
    prefix
  end

  def respond(tweet, meta)
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
        @bot.reply(tweet, prefix + text)
      end
    else
      @bot.log "#{username} unfollowed :'( :'("
      @bot.twitter.unfollow(username)
    end
  end

  def interesting?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase)
    !!(tokens.find { |t| @top100.include? t })
  end

  def very_interesting?(text)
    tokens = Ebooks::NLP.tokenize(text.downcase)
    tokens.select{ |t| @top50.include? t }.uniq.count > 1
  end
end

Ebooks::Bot.new("horse_inky") do |bot|
  # make a bot for @horse_inky using the @inky corpus
  HorseBot.new bot, "inky"
end
