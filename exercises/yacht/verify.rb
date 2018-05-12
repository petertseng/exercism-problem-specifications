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

IMPLS = {
  'correct' => {},
  '4oak only accept four' => {
    'four of a kind' => ->(hand) {
      hand[:by_count][4]&.first&.*(4) || 0
    },
  },
  'no pairs for straight' => {
    'little straight' => ->(hand) {
      hand[:distinct_counts].size == 5 ? 30 : 0
    },
    'big straight' => ->(hand) {
      hand[:distinct_counts].size == 5 ? 30 : 0
    },
  },
  'missing number for straight' => {
    'little straight' => ->(hand) {
      hand[:rank_count].has_key?(6) ? 0 : 30
    },
    'big straight' => ->(hand) {
      hand[:rank_count].has_key?(1) ? 0 : 30
    },
  },
  # https://github.com/exercism/problem-specifications/pull/1232
  'two uniques for full house' => {
    'full house' => ->(hand) {
      hand[:distinct_counts].size == 2 ? hand[:total] : 0
    },
  },
}.freeze

multi_verify(json['cases'], property: 'score', implementations: IMPLS.map { |name, merge| {
  name: name,
  should_fail: !merge.empty?,
  f: ->(i, _) {
    dice = i['dice']
    rank_count = dice.group_by(&:itself).transform_values(&:size).freeze
    by_count = rank_count.keys.group_by(&rank_count)

    untested_categories.delete(i['category'])

    CATEGORIES.merge(merge).fetch(i['category'])[{
      rank_count: rank_count,
      total: rank_count.sum { |k, v| k * v },
      by_count: by_count,
      distinct_counts: by_count.flat_map { |k, vs| [k] * vs.size }.freeze,
    }]
  },
}})

raise "#{untested_categories} were not tested" unless untested_categories.empty?
