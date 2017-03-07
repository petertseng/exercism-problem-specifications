require 'json'
require_relative '../../verify'

# Notice that the operations always cycle back and forth between:
# A: from -> to
# B: one of: fill from, or empty to.
# Further note that we never need to check goal during a B move.
def two_bucket_oneway(capacity_from, capacity_to, goal)
  return [1, 0, :from] if capacity_from == goal
  return [2, capacity_from, :to] if capacity_to == goal
  raise 'impossible' if goal % capacity_from.gcd(capacity_to) != 0

  water_from = capacity_from
  water_to = 0
  steps = 1

  while true
    headroom = capacity_to - water_to
    if headroom > water_from
      # from->to will not fill to.
      # do from->to, then fill from.
      water_to += water_from
      return [steps + 1, 0, :to] if water_to == goal
      water_from = capacity_from
    else
      # from->to will fill to.
      # do from->to, then empty to.
      water_from -= headroom
      return [steps + 1, capacity_to, :from] if water_from == goal
      water_to = 0
    end
    steps += 2
  end
end

OTHER = {
  'one' => 'two'.freeze,
  'two' => 'one'.freeze,
}

def two_bucket_solve(one, two, goal, start)
  from, to = case start
    when 'one'; [one, two]
    when 'two'; [two, one]
    else raise "Invalid start #{start}"
  end

  steps, other_bucket_water, bucket_with_goal = two_bucket_oneway(from, to, goal)

  {
    'moves' => steps,
    'goalBucket' => {from: start, to: OTHER[start]}.fetch(bucket_with_goal),
    'otherBucket' => other_bucket_water,
  }
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'measure') { |i, _|
  two_bucket_solve(i['bucketOne'], i['bucketTwo'], i['goal'], i['startBucket'])
}
