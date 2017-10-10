require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def each_row
  Enumerator.new { |e|
    prev = [1].freeze
    e << prev
    loop {
      e << prev = prev.each_cons(2).map(&:sum).unshift(1).push(1).freeze
    }
  }
end

verify(json['cases'], property: 'rows') { |i, _|
  raise 'negative not allowed' if i['count'] < 0
  each_row.take(i['count'])
}
