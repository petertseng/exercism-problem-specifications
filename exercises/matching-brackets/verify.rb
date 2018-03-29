require 'json'
require_relative '../../verify'

class BracketMatcher
  class ParseError < Exception; end

  PAIRS = {
    ?{ => ?},
    ?[ => ?],
    ?( => ?),
  }.each_value(&:freeze).freeze
  CLOSES = PAIRS.invert.freeze

  def initialize(str)
    @str = str.freeze
  end

  def many_balanced(pos)
    while pos < @str.size
      if (close_token = PAIRS[@str[pos]])
        # It was an open token, so look for the close token.
        pos = close_pair(pos + 1, close_token)
      elsif CLOSES.has_key?(@str[pos])
        # It was a close token, so stop.
        break
      else
        # It was any other character, so consume it.
        pos += 1
      end
    end

    pos
  end

  def close_pair(pos, close_token)
    new_pos = many_balanced(pos)

    err_prefix = "Expected #{close_token} at pos #{new_pos} (opened at #{pos - 1})"

    raise ParseError, "#{err_prefix}, but ran out of characters instead" if new_pos >= @str.size
    raise ParseError, "#{err_prefix}, but got #{@str[new_pos]} instead" if @str[new_pos] != close_token

    # Advance by 1 to consume close token
    new_pos + 1
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'isPaired', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      begin
        BracketMatcher.new(i['value']).many_balanced(0) == i['value'].size
      rescue BracketMatcher::ParseError
        false
      end
    },
  },
  {
    name: 'keep deleting',
    f: ->(i, _) {
      brackets = ['{}', '()', '[]']
      r = brackets.join.each_char.to_h { |c| [c, true] }
      s = i['value'].each_char.select(&r).join
      while brackets.map { |b| s.gsub!(b, '') }.any?
        # do nothing; condition mutates s
      end
      s.empty?
    },
  },
  {
    name: 'stack',
    f: ->(i, _) {
      stack = []
      i['value'].each_char { |c|
        stack << c if BracketMatcher::PAIRS.has_key?(c)
        if (o = BracketMatcher::CLOSES[c])
          return false unless stack.pop == o
        end
      }
      stack.empty?
    },
  },
  {
    name: 'stack, but returns too early',
    should_fail: true,
    f: ->(i, _) {
      stack = []
      i['value'].each_char { |c|
        stack << c if BracketMatcher::PAIRS.has_key?(c)
        if (o = BracketMatcher::CLOSES[c])
          return stack.pop == o
        end
      }
      stack.empty?
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1300
    name: 'stack, but returns too early guarded',
    should_fail: true,
    f: ->(i, _) {
      stack = []
      i['value'].each_char { |c|
        stack << c if BracketMatcher::PAIRS.has_key?(c)
        if (o = BracketMatcher::CLOSES[c])
          return false unless stack.pop == o
          return true if stack.empty?
        end
      }
      stack.empty?
    },
  },
  {
    name: 'stack with garbage remaining',
    should_fail: true,
    f: ->(i, _) {
      stack = []
      i['value'].each_char { |c|
        stack << c if BracketMatcher::PAIRS.has_key?(c)
        if (o = BracketMatcher::CLOSES[c])
          return false unless stack.pop == o
        end
      }
      true
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1392
    name: 'stack but extra closes are ignored',
    should_fail: true,
    f: ->(i, _) {
      stack = []
      i['value'].each_char { |c|
        stack << c if BracketMatcher::PAIRS.has_key?(c)
        if (o = BracketMatcher::CLOSES[c])
          return false if stack.pop&.!=(o)
        end
      }
      stack.empty?
    },
  },
  {
    name: 'count only',
    should_fail: true,
    f: ->(i, _) {
      open = BracketMatcher::PAIRS.transform_values { 0 }
      i['value'].each_char { |c|
        open[c] += 1 if open.has_key?(c)
        if (o = BracketMatcher::CLOSES[c])
          return false if open[o] == 0
          open[o] -= 1
        end
      }
      open.values.all?(&:zero?)
    },
  },
])
