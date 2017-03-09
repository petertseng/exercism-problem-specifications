require 'json'
require_relative '../../verify'

ALPHA = 'abcdefghijklmnopqrstuvwxyz'.freeze

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'rotate') { |i, _|
  rot = ALPHA.chars.rotate(i['shiftKey']).join
  i['text'].tr(ALPHA + ALPHA.upcase, rot + rot.upcase)
}
