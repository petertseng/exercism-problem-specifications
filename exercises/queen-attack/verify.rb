require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

raise "There should be exactly two cases, not #{json['cases'].size}" if json['cases'].size != 2

verify(json['cases'][0]['cases'], property: 'create') { |i, _|
  i['queen']['position'].values_at('row', 'column').all? { |x| (0...8).cover?(x) } ? 0 : (raise 'invalid')
}

verify(json['cases'][1]['cases'], property: 'canAttack') { |i, _|
  w, b = %w(white black).map { |color|
    i["#{color}_queen"]['position'].values_at('row', 'column')
  }
  diffs = w.zip(b).map { |wb| wb.reduce(:-).abs }
  diffs.include?(0) || diffs.uniq.size == 1
}
