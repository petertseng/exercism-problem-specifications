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
  INTERVAL = {?m => 0, ?M => 1, ?A => 2}.freeze

  def self.pitches(tonic, intervals)
    notes = NOTES.rotate(INDEX[tonic])
    if intervals
      indices = [0] + intervals.each_char.map(&INTERVAL)
      # I am sorry to use a select with side-effect.
      # Perhaps it should be a fold instead.
      notes.select! { |note|
        (indices.first == 0).tap { |b|
          b ? indices.shift : indices[0] -= 1
        }
      }
    end
    notes.map(&(FLAT.include?(tonic) ? :flat : :sharp)).freeze
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'].flat_map { |c| c['cases'] }, %w(chromatic interval))

verify(cases['chromatic'], property: 'chromatic') { |i, _|
  Scale.pitches(i['tonic'], nil)
}

verify(cases['interval'], property: 'interval') { |i, _|
  Scale.pitches(i['tonic'], i['intervals'])
}
