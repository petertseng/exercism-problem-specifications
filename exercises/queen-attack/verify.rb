require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

verify(json['cases'][0]['cases'], property: 'create') { |i, _|
  i['queen']['position'].values_at('row', 'column').all? { |x| (0...8).cover?(x) } ? 0 : (raise 'invalid')
}

multi_verify(json['cases'][1]['cases'], property: 'canAttack', implementations: [
  {
    name: 'correct',
    f: ->(i, _) {
      w, b = %w(white black).map { |color|
        i["#{color}_queen"]['position'].values_at('row', 'column')
      }
      diffs = w.zip(b).map { |wb| wb.reduce(:-).abs }
      diffs.include?(0) || diffs.uniq.size == 1
    },
  },
  {
    name: 'incorrectly using abs to calculate falling diagonal',
    should_fail: true,
    f: ->(i, _) {
      w, b = %w(white black).map { |color|
        i["#{color}_queen"]['position'].values_at('row', 'column')
      }
      same_rank_or_file = w.zip(b).any? { |wb| wb.reduce(:==) }
      same_rising = [w, b].uniq(&:sum).size == 1
      same_falling = [w, b].uniq { |wb| wb.reduce(:-).abs }.size == 1
      same_rank_or_file || same_rising || same_falling
    },
  },
])
