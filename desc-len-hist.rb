require 'json'

def cases(h)
  # top-level won't have a description, but all lower levels will.
  # therefore we have to unconditionally flat_map cases on the top level.
  # on lower levels we either flat_map cases or just return individuals.
  cases = ->(hh, path = [].freeze) {
    hh['cases']&.flat_map { |c|
      cases[c, (path + [hh['description'].freeze]).freeze]
    } || [hh.merge(path: path)]
  }
  h['cases'].flat_map(&cases)
end

maxes = []
freq = Hash.new(0)

recurse = ARGV.delete('-r')

Dir.glob("#{__dir__}/exercises/*/canonical-data.json") { |f|
  exercise = File.basename(File.dirname(f))
  lens = cases(JSON.parse(File.read(f))).map { |c|
    arbitrary = ?/
    ((recurse ? c[:path] : []) + [c['description']]).join(arbitrary).size
  }
  maxes << [lens.max, exercise]
  lens.each { |l| freq[l] += 1 }
}

n = ARGV.empty? ? 10 : Integer(ARGV.first)

bucket_size = 5

(0..maxes.map(&:first).max).step(bucket_size) { |left|
  right = left + bucket_size
  v = freq.values_at(*(left...right).to_a).sum
  puts '%3d - %3d: %d' % [left, right, v]
}

puts "total: #{freq.values.sum}"

puts "top #{n}:"
maxes.max_by(n, &:first).each { |x| puts '%3d %s' % x }
