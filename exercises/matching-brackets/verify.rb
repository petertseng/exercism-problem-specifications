require 'json'
require_relative '../../verify'

class BracketMatcher
  class ParseError < Exception; end

  PAIRS = {
    ?{ => ?},
    ?[ => ?],
    ?( => ?),
  }.each_value(&:freeze).freeze
  CLOSES = PAIRS.values.to_h { |v| [v, true] }.freeze

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

verify(json['cases'], property: 'isPaired') { |i, _|
  begin
    BracketMatcher.new(i['value']).many_balanced(0) == i['value'].size
  rescue BracketMatcher::ParseError
    false
  end
}
