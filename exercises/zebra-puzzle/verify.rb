require 'json'
require_relative '../../verify'

# Interpretation 1: norwegian lives in house 1,
# but we don't know whether that house is leftmost or rightmost (so we only know green is next to ivory)
# Interpretation 2: We know green house is ivory house + 1 (1 is left, 5 is right)
# but we don't know whether the Norwegian's house is first on the left or first on the right (1 or 5)
# The two rulesets should be isomorphic.
# Both give two possible solutions, but the answers to both queries are the same.
RULES2 = false

rules = ([
  [[:person, :englishman], :==, [:colour, :red]],
  [[:person, :spaniard], :==, [:pet, :dog]],
  [[:drink, :coffee], :==, [:colour, :green]],
  [[:person, :ukranian], :==, [:drink, :tea]],
  [[:colour, :green], RULES2 ? :right_of : :next_to, [:colour, :ivory]],
  [[:cigarette, :old_gold], :==, [:pet, :snails]],
  [[:cigarette, :kools], :==, [:colour, :yellow]],
  [[:drink, :milk], :==, [:house, 3]],
] + (
  RULES2 ? [
    [[:person, :norwegian], :!=, [:house, 2]],
    [[:person, :norwegian], :!=, [:house, 3]],
    [[:person, :norwegian], :!=, [:house, 4]],
  ] : [[[:person, :norwegian], :==, [:house, 1]]]
) + [
  [[:cigarette, :chesterfields], :next_to, [:pet, :fox]],
  [[:cigarette, :kools], :next_to, [:pet, :horse]],
  [[:cigarette, :lucky_strike], :==, [:drink, :orange_juice]],
  [[:person, :japanese], :==, [:cigarette, :parliaments]],
  [[:person, :norwegian], :next_to, [:colour, :blue]],
]).map { |r| r.map(&:freeze).freeze }.freeze

attributes = {
  colour: %i(red green ivory yellow blue),
  person: %i(englishman spaniard ukranian norwegian japanese),
  pet: %i(dog snails fox horse zebra),
  drink: %i(coffee tea milk orange_juice water),
  cigarette: %i(old_gold kools chesterfields lucky_strike parliaments),
}.each_value(&:freeze).freeze

def house(assignment, (k, v))
  k == :house ? v - 1 : (ka = assignment[k]) && (ka.index(v) or raise "#{v} not in #{k}, need #{ka}")
end

def matches?(assignment, (a, op, b))
  house_a = house(assignment, a)
  house_b = house(assignment, b)
  return nil if house_a.nil? || house_b.nil?

  case op
  when :==; house_a == house_b
  when :!=; house_a != house_b
  when :right_of; house_a == house_b + 1
  when :next_to; [1, -1].include?(house_a - house_b)
  else raise "Unknown op #{op}"
  end
end

# Try the attributes that are most-mentioned first.
mentions = rules.flat_map { |(a, _), _, (b, _)| [a, b] }.group_by(&:itself).transform_values(&:size)

solutions = (attributes.keys.sort_by { |k| -mentions[k] }).reduce([{}]) { |assignments, k|
  assignments.product(attributes[k].permutation.to_a).map { |previous, current|
    previous.merge(k => current)
  }.select { |assignment|
    rules.all? { |r| matches?(assignment, r) != false }
  }
}

puts "#{solutions.size} possible solutions"

def single_answer(answers)
  answers.all? { |a| a == answers[0] } ? answers[0] : (raise "#{answers} is ambiguous")
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify([json['cases'][0]], property: 'drinksWater') {
  single_answer(solutions.map { |a| a[:person][house(a, [:drink, :water])] }).to_s.capitalize
}

verify([json['cases'][1]], property: 'ownsZebra') {
  single_answer(solutions.map { |a| a[:person][house(a, [:pet, :zebra])] }).to_s.capitalize
}
