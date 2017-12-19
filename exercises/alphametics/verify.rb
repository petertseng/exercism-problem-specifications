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

  DIGITS = Set.new(0..9).freeze

  def self.solutions(terms, sum)
    terms = terms.map { |term| term.map(&:freeze).freeze }.freeze
    sum = sum.map(&:freeze).freeze
    nines = terms.flatten.uniq.to_h { |l| [l, 9] }.freeze
    all_letters = Set.new(terms.flatten + sum).freeze

    # Each element of sub_solutions is [assignment, carry]
    # where carry is the value carried FROM the next column to be solved.
    sub_solutions = [[{}.freeze, 0].freeze]
    prev_letters = Set.new

    cant_be_zero = Set.new(terms.map(&:first) + [sum.first]).freeze

    column_term_letters = (1..sum.size).map { |column|
      terms.map { |term| term[-column] }.compact.tally.freeze
    }.unshift(nil).freeze

    # Solve ONE column at a time (starting from the leftmost)
    # so that we narrow down the search space earlier.
    sum.size.step(1, by: -1).each { |column|
      term_letters = column_term_letters[column]
      sum_letter = sum[-column]
      column_letters = Set.new(term_letters.keys + [sum_letter])
      new_letters = (column_letters - prev_letters).to_a
      new_nonzeroes = (cant_be_zero & new_letters).map { |i| new_letters.index(i) }

      sub_solutions = sub_solutions.flat_map { |sub_solution, carry_out|
        possible_carries = column == 1 ? 0..0 : 0..max_carry_into(column_term_letters, column, nines.merge(sub_solution))
        unassigned_numbers = DIGITS - sub_solution.values
        unassigned_numbers.to_a.permutation(new_letters.size).filter_map { |new_assigns|
          next if new_nonzeroes.any? { |digit| new_assigns[digit] == 0 }
          proposed = sub_solution.merge(new_letters.zip(new_assigns).to_h).freeze
          lhs, rhs = add(proposed, term_letters, sum_letter)
          needed_carry_in = carry_out * 10 + rhs - lhs
          next unless possible_carries.cover?(needed_carry_in)
          [proposed, needed_carry_in].freeze
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

    sub_solutions.map(&:first)
  end

  def self.max_carry_into(column_terms, column, assignment)
    (1...column).reduce(0) { |carry_in, col|
      (column_terms[col].sum { |n, freq| assignment.fetch(n) * freq } + carry_in) / 10
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
    lhs = term_letters.sum { |n, freq| assignment.fetch(n) * freq }
    rhs = assignment.fetch(sum_letter)
    [lhs, rhs]
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'solve') { |i, _|
  Alphametics.solve(i['puzzle'])
}
