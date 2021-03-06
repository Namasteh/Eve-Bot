# This plugin requires you to have a file in the bot's root directory named
# memos.yaml. Please be certain that this file is in your directory.

require 'yaml'
require_relative "config/check_ignore"

module Cinch::Plugins
  class Memo
    include Cinch::Plugin

    set :plugin_name, 'memo'
    set :help, <<-USAGE.gsub(/^ {6}/, '')
    Sometimes MemoServ can be confusing or some users just don't notice that they have messages. This is a good way to leave messages for users! Please use this command in a PM with me.
    Usage:
    * !memo <nick> <message>: I will store a message for the specified nick until they speak again in a channel I am in, then I will PM them your memo!
    USAGE

    def initialize(*args)
      super
      if File.exist?('docs/memos.yaml')
        @memos = YAML.load_file('docs/memos.yaml')
      else
        @memos = {}
      end
    end

    listen_to :message

    match /memo (.+?) (.+)/i

    def listen(m)
      if @memos.key?(m.user.nick) and @memos[m.user.nick].size > 0
        while @memos[m.user.nick].size > 0
          msg = @memos[m.user.nick].shift
          m.user.send msg
        end
        @memos.delete m.user.nick
        update_store
      end
    end

    def execute(m, nick, message)
      return if check_ignore(m.user)
      if nick == m.user.nick
        m.reply "You can't leave memos for yourself..."
      elsif nick == bot.nick
        m.reply "You can't leave memos for me..."
      elsif @memos.key?(nick)
        msg = make_msg(m.user.nick, m.channel, message, Time.now)
        @memos[nick] << msg
        m.reply "Added memo for #{nick}"
        update_store
      else
        @memos[nick] ||= []
        msg = make_msg(m.user.nick, m.channel, message, Time.now)
        @memos[nick] << msg
        m.reply "Added memo for #{nick}"
        update_store
      end
    end

    def update_store
      synchronize(:update) do
        File.open('docs/memos.yaml', 'w') do |fh|
          YAML.dump(@memos, fh)
        end
      end
    end

    def make_msg(nick, channel, text, time)
      t = time.strftime("%Y-%m-%d")
      "Memo from #{nick} sent at #{t}: #{text}"
    end
  end
end

## Written by Richard Banks for Eve-Bot "The Project for a Top-Tier IRC bot.
## E-mail: namaste@rawrnet.net
## Github: Namasteh
## Website: www.rawrnet.net
## IRC: irc.sinsira.net #Eve
## If you like this plugin please consider tipping me on gittip
