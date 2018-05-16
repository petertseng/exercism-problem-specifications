require 'json'
require_relative '../../verify'

module Lift; refine Symbol do
  def lift
    ->(a, b) { [to_proc[a, b]] }
  end
end; end

class Forth
  using Lift

  def initialize
    @stack = []
    @user_words = {}
  end

  def size
    @stack.size
  end

  def stack
    @stack.dup
  end

  def eval(s)
    def_splits = s.split(?;).map { |ds| ds.strip.split }

    def_splits.each { |maybe_def|
      if maybe_def.first == ?:
        target = maybe_def[1]
        raise "Can't redefine a number #{target}" if target.to_i.to_s == target
        store_def(target, maybe_def[2..-1])
      else
        eval_terms(maybe_def)
      end
    }
  end

  def store_def(target, definition)
    @user_words[target.downcase] = definition.flat_map { |tok|
      @user_words[tok.downcase] || tok
    }
  end

  def eval_terms(terms)
    terms.each { |term|
      if term.to_i.to_s == term
        @stack << term.to_i
        next
      elsif @user_words.has_key?(term.downcase)
        eval_terms(@user_words[term.downcase])
        next
      end

      case term.downcase
      when ?+
        with_two(:+.lift)
      when ?-
        with_two(:-.lift)
      when ?*
        with_two(:*.lift)
      when ?/
        with_two(:/.lift)
      when 'dup'
        with_one { |a| [a, a] }
      when 'drop'
        with_one { |_| [] }
      when 'swap'
        with_two { |a, b| [b, a] }
      when 'over'
        with_two { |a, b| [a, b, a] }
      else
        raise "Unknown word #{term}"
      end
    }
  end

  def with_two(explicit_block = nil)
    raise "Stack has #{size} but needs two" unless size >= 2
    a = @stack.pop
    b = @stack.pop
    @stack.concat(explicit_block ? explicit_block[b, a] : yield(b, a))
  end

  def with_one
    raise "Stack has #{size} but needs one" unless size >= 1
    a = @stack.pop
    @stack.concat(yield(a))
  end
end

class BadForth < Forth
  def store_def(target, definition)
    @user_words[target.downcase] = definition
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

multi_verify(json['cases'].flat_map { |c| c['cases'] }, property: 'evaluate', implementations: [Forth, BadForth].map { |forth|
  {
    name: forth,
    should_fail: forth != Forth,
    f: ->(i, _) {
      begin
        i['instructions'].each_with_object(forth.new) { |s, f| f.eval(s) }.stack
      rescue SystemStackError
        raise TestFailure
      end
    }
  }
})
