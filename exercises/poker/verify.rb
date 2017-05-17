require 'json'
require_relative '../../verify'

class Card
  VALID_SUITS = 'SCDH'.freeze

  ACE = 14

  attr_reader :suit, :rank
  def initialize(repr)
    @suit = repr[-1].freeze
    raise "Invalid suit #{@suit}" unless VALID_SUITS.include?(@suit)
    @rank = case (r = repr[0...-1])
      when ?A; ACE
      when ?K; 13
      when ?Q; 12
      when ?J; 11
      else
        r.to_i.tap { |as_i|
          raise "Invalid rank #{r}" unless 2 <= as_i && as_i <= 10
        }
      end
  end
end

class Hand
  include Comparable

  STRAIGHT_FLUSH = 8
  FOUR_OF_A_KIND = 7
  FULL_HOUSE = 6
  FLUSH = 5
  STRAIGHT = 4
  THREE_OF_A_KIND = 3
  TWO_PAIR = 2
  PAIR = 1
  NOTHING = 0
  KINDS = NOTHING..STRAIGHT_FLUSH

  def initialize(cards)
    @cards = cards.map { |c| Card.new(c) }.freeze
    @value = evaluate.freeze
  end

  def size
    @cards.size
  end

  def flush?
    @flush ||= begin
      suit = @cards.first.suit
      @cards.all? { |c| c.suit == suit }
    end
  end

  def <=>(other)
    @value <=> other.value
  end

  def kind
    @value.first
  end

  protected

  attr_reader :value

  private

  def evaluate
    ranks = @cards.map(&:rank).sort.reverse.freeze
    # by_count: Hash[Int (count) => Array[Int] (ranks that are present with that count)]
    by_count = ranks.group_by(&:itself).group_by { |_, v| v.size }.transform_values { |v| v.map(&:first).freeze }.freeze

    # Both non-flush straights and straight flushes are going here.
    # This is safe:
    # Hands between straight flush and straight are 4OAK, full house, flush.
    # The first two are mutually exclusive with straights.
    if by_count.fetch(1, []).size == size
      category = flush? ? STRAIGHT_FLUSH : STRAIGHT
      return [category, 5] if ranks == [Card::ACE, 5, 4, 3, 2]
      return [category, ranks.first] if ranks.first - ranks.last == size - 1
    end

    return [FOUR_OF_A_KIND, by_count[4].first, by_count[1].first] if by_count.has_key?(4)
    return [FULL_HOUSE, by_count[3].first, by_count[2].first] if by_count.has_key?(3) && by_count.has_key?(2)
    return [FLUSH] + ranks if flush?
    # Straights handled above.
    return [THREE_OF_A_KIND, by_count[3].first] + by_count[1] if by_count.has_key?(3)
    return [TWO_PAIR] + by_count[2] + by_count[1] if by_count.fetch(2, []).size > 1
    return [PAIR] + by_count[2] + by_count[1] if by_count.has_key?(2)
    [NOTHING] + by_count[1]
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

# Make sure all kinds have been parsed at least once,
# make sure all consecutive pairs have been done at least once.
kinds_represented = {}
kind_pairs_represented = {}

verify(json['cases'], property: 'bestHands') { |i, _|
  hands = i['hands'].map { |h| Hand.new(h.split) }.freeze

  hands.each { |h| kinds_represented[h.kind] = true }
  hands.combination(2) { |hs| kind_pairs_represented[hs.map(&:kind).sort] = true }

  # Unfortunately, max_by gets only one element.
  # So we'll iterate twice, since our data sets are small.
  # TODO: If looking for one-pass, implement maxes_by on Enumerable.
  one_best = hands.max
  i['hands'].zip(hands).select { |_, parsed| parsed == one_best }.map(&:first)
}

Hand::KINDS.each { |k|
  next if kinds_represented[k]
  puts "No test for kind #{k}"
  at_exit { raise 'tests incomplete' }
}
puts 'all distinct kinds represented'
Hand::KINDS.each_cons(2) { |ks|
  next if kind_pairs_represented[ks]
  puts "No test for kind pair #{ks}"
  at_exit { raise 'tests incomplete' }
}
puts 'all adjacent kind pairs represented'
