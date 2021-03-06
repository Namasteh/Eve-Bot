require_relative "config/check_ignore"

class Float
  def prettify
    to_i == self ? to_i : self
  end
end

module Cinch
  module Plugins
    class Decide
      include Cinch::Plugin

      set :plugin_name, 'decider'
      set :help, <<-USAGE.gsub(/^ {6}/, '')
      This plugin has a few commands to help you decide if you can't on your own. Have fun!
      Usage:
      - !decide <option 1> [<,> or <or> or </>] <option 2>: The bot will choose for you based on the options you provide. Note: please be sure to include a splitter [<,> or <or> or </>] or the bot won't respond.
      - !choose <option 1> [<,> or <or> or </>] <option 2>: The bot will choose for you based on the options you provide. Note: please be sure to include a splitter [<,> or <or> or </>] or the bot won't respond.
      - !coin: The bot will "flip a coin" and tell you the result.
      - !token <length>: The bot will generate a token for you, the length must be any of the following: 2, 4, 8, 16, 32, 64, 128, and 256.
      USAGE

      def decide!(list)
        return if check_ignore(m.user)
        list = list.gsub(/\x03([0-9]{2}(,[0-9]{2})?)?/,"") #strips IRC colors
        options = list.gsub(/ or /i, ",").split(",").map(&:strip).reject(&:empty?)
        options[Random.new.rand(1..options.length)-1]
      end

      match /decide (.+)/i, method: :execute_decision
      match /choose (.+)/i, method: :execute_decision

      def execute_decision(m, list)
        return if check_ignore(m.user)
        m.safe_reply("I choose \"#{decide! list}\"!",true);
      end

      match "coin", method: :execute_coinflip
      def execute_coinflip(m)
        return if check_ignore(m.user)
        face = Random.new.rand(1..2) == 1 ? "heads" : "tails";
        m.safe_reply("The coin says: \"#{face}\"!",true);
      end

      valid_number = /(?:-|\+)?\d*\.?\d+(?:e)?(?:-|\+)?\d*\.?\d*/

      match /rand (#{valid_number}) (#{valid_number})/i, method: :execute_random
      def execute_random(m, x, y)
        return if check_ignore(m.user)
        x = x.to_f.prettify
        y = y.to_f.prettify
        xy = "(x=#{x}, y=#{y})"
        return m.reply("X must not be equal to Y. #{xy}", true) if x == y
        return m.reply("X must be lesser than Y. #{xy}") if x > y

        m.reply "Your number is: #{Random.new.rand(x..y)}.", true
      end

      match /token (\d+)/i, method: :execute_token
      def execute_token(m, length)
        return if check_ignore(m.user)
        max_length = 256
        def power_of_2?(number)
          return if check_ignore(m.user)
          (1..32).each { |bit| return true if number == (1 << bit) }
          false
        end

        return m.reply "Your token length can only be 2, 4, 8, 16, 32, 64, 128, and 256." unless power_of_2?(length.to_i)
        return m.reply "Your token length must be 256 or below." if length.to_i > 256
        characters = ('a'..'z').to_a + ('A'..'Z').to_a + (0..9).to_a
        key = (0..length.to_i-1).map{characters.sample}.join
        m.reply "Your token is: #{key}", true
        m.user.notice "Alternatively, you may want it in these formats: #{key.scan(/.{0,#{key.length / (key.length / 8)}}/).reject(&:empty?).join("-")}, #{key.upcase.scan(/.{0,#{key.length / (key.length / 8)}}/).reject(&:empty?).join("-")}"
      end
    end
  end
end

## Written by Richard Banks for Eve-Bot "The Project for a Top-Tier IRC bot.
## E-mail: namaste@rawrnet.net
## Github: Namasteh
## Website: www.rawrnet.net
## IRC: irc.sinsira.net #Eve
## If you like this plugin please consider tipping me on gittip
