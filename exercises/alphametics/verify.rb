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

    # Each element of sub_solutions is [assignment, carry]
    # where carry is the value carried into the next column to be solved.
    sub_solutions = [[{}, 0]]
    prev_letters = Set.new

    cant_be_zero = Set.new(terms.map(&:first) + [sum.first]).freeze

    # Solve ONE column at a time (starting from the rightmost)
    # so that we narrow down the search space earlier.
    (1..sum.size).each { |column|
      term_letters = terms.map { |term| term[-column] }.compact
      sum_letter = sum[-column]
      column_letters = Set.new(term_letters + [sum_letter])
      new_letters = (column_letters - prev_letters).to_a
      new_nonzeroes = (cant_be_zero & new_letters).map { |i| new_letters.index(i) }

      sub_solutions = sub_solutions.flat_map { |sub_solution, carry_in|
        unassigned_numbers = DIGITS - sub_solution.values
        unassigned_numbers.to_a.permutation(new_letters.size).map { |new_assigns|
          next nil if new_nonzeroes.any? { |digit| new_assigns[digit] == 0 }
          proposed = sub_solution.merge(new_letters.zip(new_assigns).to_h)
          carry_out = try_add(proposed, carry_in, term_letters, sum_letter)
          carry_out && [proposed, carry_out]
        }.compact
      }

      prev_letters |= new_letters
    }

    sub_solutions.select { |_, carry_out| carry_out == 0 }.map(&:first)
  end

  # try_add attempts to evaluate the given column under the given assignment.
  #
  # @return [Integer] the carry-out, if the assignment induces a valid result
  # @return [nil] if the assignment does not induce a valid result
  def self.try_add(assignment, carry_in, term_letters, sum_letter)
    lhs = term_letters.sum { |n| assignment.fetch(n) } + carry_in
    rhs = assignment.fetch(sum_letter)
    lhs % 10 == rhs ? lhs / 10 : nil
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'solve') { |i, _|
  Alphametics.solve(i['puzzle'])
}
