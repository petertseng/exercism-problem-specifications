require 'json'
require_relative '../../verify'

def knapsack(weight, items, i = 0)
  return 0 unless (item = items[i])
  return 0 if weight == 0

  without_item = knapsack(weight, items, i + 1)
  weight_with = weight - item['weight']
  return without_item if weight_with < 0

  with_item = item['value'] + knapsack(weight_with, items, i + 1)

  [with_item, without_item].max
end

def greedy(items, max)
  total_weight = 0
  items.take_while { |it| (total_weight += it['weight']) <= max }.sum { |it| it['value'] }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'maximumValue', implementations: [
  {
    name: 'correct',
    f: -> (i, _) {
      knapsack(i['maximumWeight'], i['items'].map(&:freeze).freeze)
    },
  },
  {
    name: 'exhaustive',
    f: -> (i, _) {
      subsets = (0...(2 ** i['items'].size)).map { |bits|
        i['items'].select.with_index { |_, i| bits[i] != 0 }
      }
      subsets.select { |subset|
        subset.sum { |it| it['weight'] } <= i['maximumWeight']
      }.map { |subset| subset.sum { |it| it['value'] } }.max
    },
  },
  {
    name: 'greedy by weight',
    should_fail: true,
    f: -> (i, _) {
      greedy(i['items'].sort_by { |it| it['weight'] }, i['maximumWeight'])
    },
  },
  {
    name: 'greedy by value',
    should_fail: true,
    f: -> (i, _) {
      greedy(i['items'].sort_by { |it| -it['value'] }, i['maximumWeight'])
    },
  },
])
