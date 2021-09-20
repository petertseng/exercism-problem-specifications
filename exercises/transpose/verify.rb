require 'json'
require_relative '../../verify'

THUMBSUP = '👍'.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'], property: 'transpose', implementations: [
  {
    name: 'pad all, trim right',
    f: ->(i, _) {
      max_size = i['lines'].map(&:size).max
      chars = i['lines'].map { |s| s.ljust(max_size, THUMBSUP).each_char }
      (chars.first || []).zip(*chars[1..-1]).map { |x| x.join.gsub(/#{THUMBSUP}+$/, '').tr(THUMBSUP, ' ') }
    }
  },
  {
    name: 'pad to longest below',
    f: ->(i, _) {
      max_len_below = 0
      padded = i['lines'].reverse.map { |l| l.ljust(max_len_below = [max_len_below, l.size].max).each_char }.reverse
      (padded.first || []).zip(*padded[1..-1]).map(&:join)
    }
  },
])
