require 'json'
require_relative '../../verify'

module NilBst refine NilClass do
  # NOTE: This << is unconventional.
  # In Ruby, << is usually understood to mutate its receiver.
  # See: Array#<<, Set#<<.
  #
  # Unfortunately, nil can't mutate itself into becoming a BST.
  # This isn't Smalltalk, you can't `become`.
  # So instead, it can only return a new object, like + would.
  #
  # I used << here solely so that I could use <<= in Bst#insert.
  # You might ask why I don't use + and += but that doesn't seem right either:
  # Bst#insert is definitely modifying its receiver, according to tests.
  # So I have to be inconsistent somewhere.
  def <<(val)
    Bst.new(val)
  end
end end

class Bst
  using NilBst

  def initialize(data)
    @data = data
    @left = nil
    @right = nil
  end

  def insert(val)
    # Too bad (b ? t : f) isn't a valid lvalue, otherwise we could do:
    # (val <= @data ? @left : @right) <<= val
    if val <= @data
      @left <<= val
    else
      @right <<= val
    end
    self
  end
  alias :<< :insert

  def to_h
    {
      'data' => @data,
      'left' => @left&.to_h,
      'right' => @right&.to_h,
    }
  end

  def to_a
    (@left&.to_a || []) + [@data] + (@right&.to_a || [])
  end
end

using NilBst

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

props = {
  'data' => :to_h,
  'sortedData' => :to_a,
}

cases = by_property(json['cases'].flat_map { |cc| cc.has_key?('cases') ? cc['cases'] : [cc] }, props.keys)

props.each { |prop, sym|
  verify(cases[prop], property: prop) { |i, _|
    i['treeData'].reduce(nil) { |tree, val| tree << val }.send(sym)
  }
}
