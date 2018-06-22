require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(roster grade))

verify(cases['roster'], property: 'roster') { |i, _|
  i['students'].sort_by(&:reverse).map(&:first)
}

verify(cases['grade'], property: 'grade') { |i, _|
  (i['students'].group_by(&:last)[i['desiredGrade']] || []).map(&:first).sort
}
