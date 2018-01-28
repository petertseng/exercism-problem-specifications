require 'json'
require 'set'
require_relative '../../verify'

class Scale
  Note = Struct.new(:sharp, :flat)

  NOTES = 'ABCDEFGA'.each_char.each_cons(2).flat_map { |x, y|
    ([[x, x]] + ('BE'.include?(x) ? [] : [["#{x}#", "#{y}b"]])).map { |n|
      Note.new(*n.map(&:freeze)).freeze
    }
  }.freeze

  INDEX = NOTES.flat_map.with_index { |note, i|
    [note.sharp, note.flat].flat_map { |acc| [[acc, i], [acc.downcase, i]] }
  }.to_h.freeze

  FLAT = Set.new(%w(F Bb Eb Ab Db Gb d g c f bb eb)).freeze
  INTERVAL = {?m => 1, ?M => 2, ?A => 3}.freeze

  def self.cumulative_sum(xs)
    sum = 0
    xs.map { |x| sum += x }.unshift(0)
  end

  def self.pitches(tonic, intervals = (?m * 12).freeze)
    notes = NOTES.rotate(INDEX[tonic]) * 2
    indices = cumulative_sum(intervals.each_char.map(&INTERVAL))
    raise "bad test #{tonic} #{intervals} -> #{indices}" if indices[-1] != 12
    notes = notes.values_at(*indices)
    raise "bad test #{tonic} #{intervals} -> #{indices} -> #{notes}" if notes[0] != notes[-1]
    notes.map(&(FLAT.include?(tonic) ? :flat : :sharp)).freeze
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))
cases = json['cases'].map { |v| v['cases'] }
raise "need 2 groups of cases not #{cases.size}" if cases.size != 2

verify(cases[0], property: 'chromatic') { |i, _|
  Scale.pitches(i['tonic'])[0..-2]
}

reimplemented_uuids = cases[1].to_h { |c| [c['reimplements'], true] }
reimplemented_uuids.delete(nil)

reimplemented, not_reimplemented = cases[1].partition { |c| reimplemented_uuids[c['uuid']] }

verify(not_reimplemented, property: 'interval') { |i, _|
  Scale.pitches(i['tonic'], i['intervals'])
}

verify(reimplemented, property: 'interval') { |i, _|
  Scale.pitches(i['tonic'], i['intervals'])[0..-2]
}
