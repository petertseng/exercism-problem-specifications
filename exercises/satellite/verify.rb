require 'json'
require_relative '../../verify'

def trees_from_traversals(preorder, inorder, debug: false)
  raise "bad sizes #{preorder} vs #{inorder}" if preorder.size != inorder.size

  # in_idxs[c] indicates indices at which c appears in the inorder traversal.
  in_idxs = inorder.each_with_index.group_by(&:first).transform_values { |gs|
    gs.map(&:last).freeze
  }.freeze

  # (pre_idx: Int) Index of the next preorder element to be considered.
  # (l: Int) Inclusive left bound of inorder elements to be considered.
  # (r: Int) Exclusive right bound of inorder elements to be considered.
  #
  # Debugging inputs (do not affect algorithm operation, just debug output):
  # (lvl: Int) Level of the tree.
  # (t: Symbol :root | :L | :R) Identifier of this level of recursion.
  #
  # Returns:
  # Array[possible tree]
  #
  # Postcondition:
  # tree's size is r - l.
  trees = ->(pre_idx, l, r, lvl, t) {
    raise "level #{lvl} #{t}: this should never happen: l #{l} > r #{r}" if l > r

    if debug
      node = l == r ? 'leaf' : "#{pre_idx} (#{preorder[pre_idx]})"
      puts "#{'    ' * lvl}#{t} #{node} #{l}...#{r} (#{inorder[l...r]})"
    end

    return [{}] if l == r
    # Consider the first element v in the preorder:
    # v is the root of the tree, by definition of preorder.
    v = preorder[pre_idx]
    raise "#{v} doesn't exist" unless (idxs = in_idxs[v])

    # Split the inorder list around instances of v, forming [L..., v, R...]
    idxs.select { |idx| (l...r).cover?(idx) }.flat_map { |idx|
      # Recurse on L and R, noting that they can be computed independently.
      lefts = trees[pre_idx + 1, l, idx, lvl + 1, :L]
      left_size = idx - l
      rights = trees[pre_idx + 1 + left_size, idx + 1, r, lvl + 1, :R]

      # combine all trees.
      lefts.product(rights).map { |left_sub, right_sub| {
        ?v => v,
        ?l => left_sub,
        ?r => right_sub,
      }}
    }

    # Proof of the postcondition, by induction:
    # when r == l, size is r - l == 0.
    # Each level of the tree contains, for some l <= idx < r:
    #   root v, contributing 1 to size
    #   left, whose bounds are l and idx
    #   right, whose bounds are idx + 1 and r
    # since each of these sizes is certainly smaller than r - l,
    # by the IH, these have sizes idx - l and r - (idx + 1)
    # for a total size of 1 + idx - l + r - idx - 1, simplifying to r - l.
    #
    # (thus, there is no need to do an explicit size check)
  }

  trees[0, 0, preorder.size, 0, :root]
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'treeFromTraversals') { |i, _|
  preorder = i['preorder'].map(&:freeze)
  inorder = i['inorder'].map(&:freeze)

  trees = trees_from_traversals(preorder, inorder, debug: ARGV.include?('-v'))

  raise "multiple possibilities: #{trees.size}\n#{trees.join("\n")}" if trees.size > 1

  trees[0]
}

# https://oeis.org/A000108
t = Time.now
[1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796].each_with_index { |n_want, i|
  a = ([1] * i).freeze
  trees = trees_from_traversals(a, a)
  raise "#{i} produced non-unique trees" if trees.uniq.size != trees.size
  raise "#{i} got #{trees.size} want #{n_want}" if trees.size != n_want
}
puts "Checked Catalan in #{Time.now - t}"
