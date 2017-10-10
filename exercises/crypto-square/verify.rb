require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'ciphertext') { |i, _|
  norm = i['plaintext'].downcase.gsub(/[^a-z0-9]/, '')
  next '' if norm.empty?
  size = (norm.size ** 0.5).ceil
  segments = norm.each_char.each_slice(size).map(&:join)
  (0...size).map { |j| segments.map { |segment| segment[j] || ' ' }.join }.join(' ')
}
