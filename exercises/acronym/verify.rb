require 'json'
require_relative '../../verify'

module AllCaps refine String do
  def all_caps?
    upcase == self
  end

  def internal_caps
    return '' if all_caps?
    self[1..-1].each_char.select(&:all_caps?).join
  end
end end

using AllCaps

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'].flat_map { |c| c['cases'] }, property: 'abbreviate') { |i, _|
  i['phrase'].delete(?').split(/[_\W]+/).map { |word| word[0] + word.internal_caps }.join.upcase
}
