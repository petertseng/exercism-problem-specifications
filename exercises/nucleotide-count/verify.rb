require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

valid = %w(A C G T).map(&:freeze).freeze

verify(json['cases'], property: 'nucleotideCounts') { |i, _|
  groups = i['strand'].each_char.group_by(&:itself)
  raise 'no' unless (groups.keys - valid).empty?
  valid.to_h { |v| [v, groups[v]&.size || 0] }
}
