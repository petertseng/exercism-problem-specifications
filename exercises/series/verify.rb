require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'slices') { |i, _|
  i['series'].each_char.each_cons(i['sliceLength']).map(&:join).tap { |x|
    raise 'Nope, empty is bad' if x.empty?
  }
}
