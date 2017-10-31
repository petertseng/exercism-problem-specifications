DEBUG = true

rules1 = [
  [[:person, :englishman], :==, [:colour, :red]],
  [[:person, :spaniard], :==, [:pet, :dog]],
  [[:drink, :coffee], :==, [:colour, :green]],
  [[:person, :ukranian], :==, [:drink, :tea]],
  [[:colour, :green], :next_to, [:colour, :ivory]],
  [[:cigarette, :old_gold], :==, [:pet, :snails]],
  [[:cigarette, :kools], :==, [:colour, :yellow]],
  [[:drink, :milk], :==, [:house, 3]],
  [[:person, :norwegian], :==, [:house, 1]],
  [[:cigarette, :chesterfields], :next_to, [:pet, :fox]],
  [[:cigarette, :kools], :next_to, [:pet, :horse]],
  [[:cigarette, :lucky_strike], :==, [:drink, :orange_juice]],
  [[:person, :japanese], :==, [:cigarette, :parliaments]],
  [[:person, :norwegian], :next_to, [:colour, :blue]],
].map { |r| r.map(&:freeze).freeze }.freeze

rules2 = [
  [[:person, :englishman], :==, [:colour, :red]],
  [[:person, :spaniard], :==, [:pet, :dog]],
  [[:drink, :coffee], :==, [:colour, :green]],
  [[:person, :ukranian], :==, [:drink, :tea]],
  [[:colour, :green], :right_of, [:colour, :ivory]],
  [[:cigarette, :old_gold], :==, [:pet, :snails]],
  [[:cigarette, :kools], :==, [:colour, :yellow]],
  [[:drink, :milk], :==, [:house, 3]],
  [[:person, :norwegian], :!=, [:house, 2]],
  [[:person, :norwegian], :!=, [:house, 3]],
  [[:person, :norwegian], :!=, [:house, 4]],
  [[:cigarette, :chesterfields], :next_to, [:pet, :fox]],
  [[:cigarette, :kools], :next_to, [:pet, :horse]],
  [[:cigarette, :lucky_strike], :==, [:drink, :orange_juice]],
  [[:person, :japanese], :==, [:cigarette, :parliaments]],
  [[:person, :norwegian], :next_to, [:colour, :blue]],
].map { |r| r.map(&:freeze).freeze }.freeze

rules = rules2
rules = rules1

class Learnings
  def initialize
    attributes = {
      house: [1, 2, 3, 4, 5],
      person: %i(englishman spaniard ukranian norwegian japanese),
      pet: %i(dog snails fox horse zebra),
      drink: %i(coffee tea milk orange_juice water),
      cigarette: %i(old_gold kools chesterfields lucky_strike parliaments),
      colour: %i(red green ivory yellow blue),
    }.each_value(&:freeze).freeze

    @attributes = attributes.keys.freeze
    @learned = attributes.keys.permutation(2).map { |c|
      [c, attributes[c[0]].map { |c0| [c0, attributes[c[1]].dup] }.to_h]
    }.to_h
    @size = attributes.values[0].size
    attributes.each { |k, v|
      raise "#{k} needs #{@size} values but has #{v}" if v.size != @size
    }
  end

  def query(k1, v1, k2)
    @learned.fetch([k1, k2]).fetch(v1).dup
  end

  def by_attr(attr)
    (@attributes - [attr]).map { |other_attr|
      @learned.fetch([attr, other_attr]).map { |v1, v2s|
        [v1, {other_attr => v2s}]
      }.to_h
    }.reduce({}) { |a, h| a.merge(h) { |_, v1, v2| v1.merge(v2) } }
  end

  def learn_equal(r1, r2)
    learn_equal_internal(r1, r2)
    puts 'LEARN EQ DONE' if DEBUG
    assert_is_symmetric
  end

  def learn_unequal(r1, r2)
    learn_unequal_internal(*r1, *r2)
    puts 'LEARN NEQ DONE' if DEBUG
    assert_is_symmetric
  end

  def learn_adjacent(r1, r2)
    learn_delta(*r1, *r2, [-1, 1])
    learn_delta(*r2, *r1, [-1, 1])

    learn_unequal_internal(*r1, *r2) if r1[0] != r2[0]

    puts 'LEARN ADJ DONE' if DEBUG
    assert_is_symmetric
  end

  def learn_right_of(r1, r2)
    learn_delta(*r1, *r2, [1])
    learn_delta(*r2, *r1, [-1])

    learn_unequal_internal(*r1, *r2) if r1[0] != r2[0]

    puts 'LEARN RIGHT_OF DONE' if DEBUG
    assert_is_symmetric
  end

  private

  def assert_is_symmetric
    @attributes.permutation(2) { |k1, k2|
      @learned.fetch([k1, k2]).each { |v1, expected_v2s|
        expected_v2s.each { |v2|
          observed_v1s = @learned.fetch([k2, k1]).fetch(v2)
          raise "Symmetry failure: #{k1} #{v1} -> #{expected_v2s} but #{k2} #{v2} -> #{observed_v1s}" unless observed_v1s.include?(v1)
        }
      }
    }
  end

  def learn_equal_internal(r1, r2)
    learn_one_side_equal(*r1, *r2)
    learn_one_side_equal(*r2, *r1)
  end

  def learn_one_side_equal(k1, v1, k2, v2)
    (query(k1, v1, k2) - [v2]).each { |not_v2|
      learn_unequal_internal(k1, v1, k2, not_v2)
    }
    (@learned.fetch([k1, k2]).keys - [v1]).each { |not_v1|
      learn_unequal_internal(k1, not_v1, k2, v2)
    }
    possibilities = query(k1, v1, k2)
    raise "Should be only one possibility left after #{k1} #{v1} = #{k2} #{v2}, not #{possibilities}" if possibilities.size != 1

    (@attributes - [k1, k2]).each { |other_k|
      k1_vals = query(k1, v1, other_k)
      k2_vals = query(k2, v2, other_k)
      (k1_vals - k2_vals).each { |other_v|
        puts "-> TRANSFER EQ: #{k1} #{v1} = #{k2} #{v2}, #{k1} #{v1} -> #{other_k} = #{k1_vals}, #{k2} #{v2} -> #{other_k} = #{k2_vals}, so #{k1} #{v1} != #{other_k} #{other_v}" if DEBUG
        learn_unequal_internal(k1, v1, other_k, other_v)
      }
    }
  end

  def learn_unequal_internal(k1, v1, k2, v2)
    learn_one_side_unequal(k1, v1, k2, v2)
    learn_one_side_unequal(k2, v2, k1, v1)
  end

  def learn_one_side_unequal(k1, v1, k2, v2)
    possibilities = @learned.fetch([k1, k2]).fetch(v1)
    return unless possibilities.include?(v2)
    possibilities.delete(v2)
    learn_equal_internal([k1, v1], [k2, possibilities[0]]) if possibilities.size == 1

    (@attributes - [k1, k2]).each { |other_k|
      if (other_v = query(k2, v2, other_k)).size == 1
        puts "-> TRANSFER NEQ: #{k1} #{v1} != #{k2} #{v2} and #{k2} #{v2} -> #{other_k} = #{other_v}, so #{k1} #{v1} != #{other_k} #{other_v[0]}" if DEBUG
        learn_unequal_internal(k1, v1, other_k, other_v[0])
      end
    }
  end

  def learn_delta(k1, v1, k2, v2, deltas)
    k1_pos = query(k1, v1, :house)
    possible_k2_pos = k1_pos.flat_map { |pos|
      deltas.map { |delta| pos + delta }
    }.uniq.select { |pos| (1..@size).cover?(pos) }

    (query(k2, v2, :house) - possible_k2_pos).each { |impossible_k2_pos|
      puts "-> POS: #{k1} #{v1} pos are #{k1_pos}, #{k2} #{v2} can't be #{impossible_k2_pos}" if DEBUG
      learn_unequal_internal(k2, v2, :house, impossible_k2_pos)
    }
  end
end

l = Learnings.new

3.times { |n|
  puts "RUN #{n}" if DEBUG
  rules.each { |a, op, b|
    puts "RULE: #{a} #{op} #{b}" if DEBUG
    case op
    when :==
      l.learn_equal(a, b)
    when :!=
      l.learn_unequal(a, b)
    when :right_of
      l.learn_right_of(a, b)
    when :next_to
      l.learn_adjacent(a, b)
    else raise "Unknown op #{op}"
    end
  }
}

p l
p l.query(:drink, :water, :person)
p l.query(:pet, :zebra, :person)
l.by_attr(:house).each { |house, attrs|
  puts "#{house}: #{attrs}"
}
