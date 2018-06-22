require 'json'
require 'set'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(add roster grade))

verify(cases['add'], property: 'add') { |i, _|
  taken_names = Set.new
  i['students'].map { |name, _| !!taken_names.add?(name) }
}

reimplemented, not_reimplemented = cases['roster'].partition { |c| c['uuid'] == 'c125dab7-2a53-492f-a99a-56ad511940d8' }

verify(reimplemented, property: 'roster') { |i, c|
  []
}

verify(not_reimplemented, property: 'roster') { |i, c|
  i['students'].sort_by(&:reverse).map(&:first).uniq
}

verify(cases['grade'], property: 'grade') { |i, _|
  (i['students'].uniq(&:first).group_by(&:last)[i['desiredGrade']] || []).map(&:first).sort
}
