require 'json'
require 'set'
require_relative '../../verify'

class Alphametics
  def self.solve(puzzle)
    terms, sum = puzzle.split(' == ', 2)
    terms = terms.split(' + ').map(&:chars)
    solutions = solutions(terms, sum.chars)
    raise "Non-unique: #{solutions}" if solutions.size > 1
    # Returns nil for no solutions; this is expected by the tests.
    solutions.first
  end

  def self.solutions(terms, sum)
    all_letters = terms.reduce(sum, :|).freeze
    # Each letter will be represented by its index in all_letters
    # (it seems it's faster to pass around the integers than the strings)
    index = all_letters.each_with_index.to_h.freeze
    terms = terms.map { |term| term.map(&index) }.freeze
    sum = sum.map(&index).freeze
    nines = terms.flatten.uniq.to_h { |l| [l, 9] }.freeze

    # Each element of sub_solutions is [assignment, carry, used_digits]
    # where carry is the value carried FROM the next column to be solved,
    # and used_digits is a bitfield indicating which digits are used.
    sub_solutions = [[{}, 0, 0]]
    prev_letters = Set.new

    cant_be_zero = Set.new(terms.map(&:first) + [sum.first]).freeze
    if cant_be_zero.size == 9
      # A rare occurrence, but helps in the biggest tests.
      zeroes = Set.new(0..9) - cant_be_zero
      raise "Impossible number of letters: #{zeroes.to_a}" if zeroes.size != 1
      zero = zeroes.first
      sub_solutions = [[{zero => 0}, 0, 1]]
      prev_letters << zero
    end

    # Solve ONE column at a time (starting from the leftmost)
    # so that we narrow down the search space earlier.
    sum.size.step(1, by: -1).each { |column|
      term_letters = terms.map { |term| term[-column] }.compact
      sum_letter = sum[-column]
      column_letters = Set.new(term_letters + [sum_letter])
      new_letters = (column_letters - prev_letters).to_a
      new_nonzeroes = (cant_be_zero & new_letters).map { |i| new_letters.index(i) }

      sub_solutions = sub_solutions.flat_map { |sub_solution, carry_out, used_digits|
        possible_carries = column == 1 ? [0] : (0..max_carry_into(terms, column, nines.merge(sub_solution)))
        unassigned_bits = 0x3ff & ~used_digits
        unassigned_numbers = (0..9).select { |i| unassigned_bits & (1 << i) != 0 }
        unassigned_numbers.to_a.permutation(new_letters.size).flat_map { |new_assigns|
          next [] if new_nonzeroes.any? { |digit| new_assigns[digit] == 0 }
          proposed = sub_solution.merge(new_letters.zip(new_assigns).to_h)
          lhs, rhs = add(proposed, term_letters, sum_letter)
          possible_carries.select { |carry_in|
            this_carry_out, this_col = (lhs + carry_in).divmod(10)
            carry_out == this_carry_out && this_col == rhs
          }.map { |cin| [proposed, cin, new_assigns.map { |i| 1 << i }.reduce(used_digits, :|)] }
        }
      }

      prev_letters |= new_letters

      # Assigned all letters, now see which ones give a possible assignment.
      if prev_letters.size == all_letters.size
        term_coeff = letter_coefficients(terms, 1)
        sum_coeff = letter_coefficients([sum], -1)
        coeffs = term_coeff.merge(sum_coeff) { |_, v1, v2| v1 + v2 }
        sub_solutions.select! { |sub_solution, _|
          coeffs.sum { |t, c| sub_solution.fetch(t) * c } == 0
        }
        break
      end
    }

    sub_solutions.map(&:first).map { |assignment|
      assignment.transform_keys { |k| all_letters[k] }
    }
  end

  def self.max_carry_into(terms, column, assignment)
    (1...column).reduce(0) { |carry_in, col|
      column_letters = terms.map { |term| term[-col] }.compact
      (column_letters.sum { |n| assignment.fetch(n) } + carry_in) / 10
    }
  end

  def self.letter_coefficients(terms, mult)
    terms.each_with_object(Hash.new(0)) { |term, h|
      term.reverse.reduce(1) { |place, c|
        h[c] += place * mult
        place * 10
      }
    }
  end

  def self.add(assignment, term_letters, sum_letter)
    lhs = term_letters.sum { |n| assignment.fetch(n) }
    rhs = assignment.fetch(sum_letter)
    [lhs, rhs]
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'solve') { |i, _|
  Alphametics.solve(i['puzzle'])
}
