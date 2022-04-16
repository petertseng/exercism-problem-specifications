require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c.has_key?('cases') ? c['cases'] : [c] }, property: 'combinations') { |i, _|
  cage = i.fetch('cage')
  raise 'bad cage' if cage.keys != %w(sum size exclude)
  (1..9).to_a.combination(cage['size']).select { |comb|
    comb.sum == cage['sum'] && (comb & cage['exclude']).empty?
  }
}
