require 'json'
require 'set'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def single_count(v)
  ->(hand) { v * (hand[:rank_count][v] || 0) }
end

def straight(except:)
  ->(hand) { hand[:distinct_counts] == [1, 1, 1, 1, 1] && !hand[:rank_count].has_key?(except) ? 30 : 0 }
end

CATEGORIES = {
  'ones'   => single_count(1),
  'twos'   => single_count(2),
  'threes' => single_count(3),
  'fours'  => single_count(4),
  'fives'  => single_count(5),
  'sixes'  => single_count(6),
  'full house' => ->(hand) { hand[:distinct_counts].sort == [2, 3] ? hand[:total] : 0 },
  'four of a kind' => ->(hand) {
    rank = [4, 5].map { |n| hand[:by_count][n]&.first }.compact.first
    rank&.*(4) || 0
  },
  'little straight' => straight(except: 6),
  'big straight' => straight(except: 1),
  'choice' => ->(hand) { hand[:total] },
  'yacht' => ->(hand) { hand[:distinct_counts] == [5] ? 50 : 0 },
}.freeze
untested_categories = Set.new(CATEGORIES.keys)

verify(json['cases'], property: 'score') { |i, _|
  dice = i['dice']
  rank_count = dice.group_by(&:itself).transform_values(&:size).freeze
  by_count = rank_count.keys.group_by(&rank_count)

  untested_categories.delete(i['category'])

  CATEGORIES.fetch(i['category'])[{
    rank_count: rank_count,
    total: rank_count.sum { |k, v| k * v },
    by_count: by_count,
    distinct_counts: by_count.flat_map { |k, vs| [k] * vs.size }.freeze,
  }]
}

raise "#{untested_categories} were not tested" unless untested_categories.empty?
