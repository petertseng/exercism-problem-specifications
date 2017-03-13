# frozen_string_literal: true

require 'json'
require_relative '../../verify'

class OCR
  def self.convert(text)
    raise "bad rows #{text.size}" unless text.size % LINES_PER_ROW == 0
    raise "bad cols #{text[0].size}" unless text[0].size % CHARS_PER_CELL == 0
    text.each_slice(LINES_PER_ROW).map { |lines|
      slices = lines.map { |l| l.chomp.each_char.each_slice(CHARS_PER_CELL) }
      slices[0].zip(*slices[1..-1]).map { |cell_rows|
        number_in_cell(cell_rows)
      }.join
    }.join(?,).freeze
  end

  LINES_PER_ROW = 4
  CHARS_PER_CELL = 3

  EMPTY = [' ', nil].freeze
  CELL_POSITIONS = [
    [EMPTY,              [?_, :top],    EMPTY],
    [[?|, :top_left],    [?_, :middle], [?|, :top_right]],
    [[?|, :bottom_left], [?_, :bottom], [?|, :bottom_right]],
    [EMPTY,              EMPTY,         EMPTY],
  ].freeze
  CELL_POSITIONS.each { |x| x.each(&:freeze); x.freeze }

  def self.number_in_cell(cell_rows)
    segments = cell_rows.zip(CELL_POSITIONS).flat_map { |rows, positions|
      rows.zip(positions).map { |cell, (expected, name)|
        # Place is empty - this segment is off.
        next [expected == ' ' ? :empty : :off, name] if cell == ' '
        # Place isn't empty, but is an unexpected character.
        # Throw out the entire cell, return '?' from the function
        return ?? if cell != expected
        # Place isn't empty and is the expected character.
        # This segment is on.
        [:on, name]
      }
    }.group_by(&:first).each_value { |v| v.map!(&:last) }

    case (segments[:on] || []).size
    when 2
      segments[:on] == %i(top_right bottom_right) ? ?1 : ??
    when 3
      segments[:on] == %i(top top_right bottom_right) ? ?7 : ??
    when 4
      segments[:off] == %i(top bottom_left bottom) ? ?4 : ??
    when 5
      case segments[:off]
      when %i(top_left bottom_right); ?2
      when %i(top_left bottom_left); ?3
      when %i(top_right bottom_left); ?5
      else; ??
      end
    when 6
      case segments[:off]
      when %i(middle); ?0
      when %i(top_right); ?6
      when %i(bottom_left); ?9
      else; ??
      end
    when 7
      ?8
    else
      ??
    end
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'convert') { |i, _|
  OCR.convert(i['rows'])
}
