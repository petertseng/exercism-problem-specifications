require 'json'
require_relative '../../verify'

THUMBSUP = '👍'.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'transpose') { |i, _|
  max_size = i['lines'].map(&:size).max
  chars = i['lines'].map { |s| s.ljust(max_size, THUMBSUP).each_char }
  (chars.first || []).zip(*chars[1..-1]).map { |x| x.join.gsub(/#{THUMBSUP}+$/, '').tr(THUMBSUP, ' ') }
}
