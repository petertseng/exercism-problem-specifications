require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'buildTree') { |i, _|
  root = nil
  children = {}

  i['records'].sort_by { |r| r['recordId'] }.each_with_index { |r, i|
    raise "wrong #{r} should have ID #{i}" if r['recordId'] != i

    if i == r['parentId']
      raise "too many roots #{root} #{r}" if root
      root = i
      children[root] = []
    else
      raise "duplicate #{i}" if children[i]
      children[i] = []
      # implicitly relying on << of nil to raise
      children[r['parentId']] << i
    end
  }

  next {} unless root
  {'node' => {'id' => root, 'children' => children[root].map { |child|
    if children[child].empty?
      # why shold this determine whether parentId exists?
      {'recordId' => child, 'parentId' => root}.freeze
    else
      {'recordId' => child, 'children' => children[child].map { |grandchild| {'recordId' => grandchild} }}.freeze
    end
  }}}
}
