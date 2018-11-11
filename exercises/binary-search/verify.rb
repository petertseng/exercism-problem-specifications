require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

class NotFound < StandardError; end

def bs(arr, val)
  subfind = ->(left, right) {
    middle = (right - 1 - left) / 2 + left
    at_middle = arr[middle]

    if right <= left
      nil
    elsif at_middle == val
      middle
    elsif val < at_middle
      subfind[left, middle]
    else
      subfind[middle + 1, right]
    end
  }
  subfind[0, arr.size]
end

def naive_bs(arr, val)
  return nil if arr.empty?

  subfind = ->(left, right) {
    return arr[left] == val ? left : nil if right == left + 1

    middle = (right - 1 - left) / 2 + left
    at_middle = arr[middle]

    if right <= left
      raise TestFailure, "This solution is too naive to handle right #{right} <= left #{left}"
    elsif at_middle == val
      middle
    elsif val < at_middle
      subfind[left, middle]
    else
      subfind[middle + 1, right]
    end
  }
  subfind[0, arr.size]
end

multi_verify(json['cases'], error_class: NotFound, property: 'find', implementations: [
  {
    name: 'built-in index',
    f: ->(i, _) {
      i['array'].index(i['value']) or raise NotFound, 'not in the array'
    },
  },
  {
    name: 'binary search',
    f: ->(i, _) {
      bs(i['array'], i['value']) or raise NotFound, 'not in the array'
    },
  },
  {
    # https://github.com/exercism/problem-specifications/pull/1399
    name: 'binary search that forgot to check bounds',
    should_fail: true,
    f: ->(i, _) {
      naive_bs(i['array'], i['value']) or raise NotFound, 'not in the array'
    },
  },
])
