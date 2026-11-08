require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'jigsawData', allowed_input_keys: [%w(pieces aspectRatio), %w(rows format), %w(inside aspectRatio), %w(rows aspectRatio), %w(pieces border format), %w(pieces format), %w(rows columns format)]) { |i, _|
  # always have rows and aspect_ratio calculated by the end of this case/when
  # TODO: could be improved by adding a bunch of rules about how to derive one piece of information from two,
  # then repeatedly applying the rules.

  case i.keys.sort
  when %w(aspectRatio pieces)
    pieces = i['pieces']
    aspect_ratio = i['aspectRatio']
    rows = ((pieces / aspect_ratio) ** 0.5).round
  when %w(format rows)
    aspect_ratio = i['format'] == 'square' ? 1 : (raise "unknown #{i}")
    rows = i['rows']
  when %w(aspectRatio inside)
    aspect_ratio = i['aspectRatio']
    rows = 1.step.find { |cand_rows|
      cols = cand_rows * aspect_ratio
      pieces = cand_rows * cols
      calc_inside = pieces - ((cand_rows + cols) * 2 - 4)
      raise "overshot #{calc_inside} (#{cand_rows} #{cols}) > #{i['inside']}" if calc_inside > i['inside']
      calc_inside == i['inside']
    }
  when %w(aspectRatio rows)
    aspect_ratio = i['aspectRatio']
    rows = i['rows']
  when %w(border format pieces)
    pieces = i['pieces']
    border = i['border']
    small = 1.step.find { |cand_small|
      cand_big = pieces / cand_small
      raise "can't do it #{cand_small * cand_big}" unless (0..pieces).cover?(cand_small * cand_big)
      cand_small * cand_big == pieces && (cand_small + cand_big) * 2 - 4 == border
    }
    case i['format']
    when 'portrait'
      rows = pieces / small
    when 'landscape'
      rows = small
    when 'square'
      if pieces == small * small
        rows = small
      else
        raise "#{small} squared doesn't make #{pieces}"
      end
    end
    cols = pieces / rows
    aspect_ratio = cols.fdiv(rows)
  else raise "unknown #{i}"
  end
  cols = (rows * aspect_ratio).round
  pieces = rows * cols

  {
    'pieces' => pieces,
    'aspectRatio' => aspect_ratio,
    'border' => border = (rows + cols) * 2 - 4,
    'inside' => pieces - border,
    'rows' => rows,
    'columns' => cols,
    'format' => (case aspect_ratio
      when 1; 'square'
      when 1..; 'landscape'
      else 'portrait'
    end)
  }
}
