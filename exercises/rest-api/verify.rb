require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'].flat_map { |c| c['cases'] }, %w(get post))

verify(cases['get'], property: 'get') { |i, _|
  # url doesn't matter.
  {'users' => i['database']['users'].select { |u| i.dig('payload', 'users')&.include?(u['name']) }}
}

verify(cases['post'], property: 'post') { |i, _|
  case i['url']
  when '/add'
    {
      'name' => i['payload']['user'],
      'owes' => {},
      'owed_by' => {},
      'balance' => 0.0,
    }
  when '/iou'
    users = i['database']['users']
    users.each { |u| %w(owes owed_by).each { |o| u[o].default = 0.0 } }

    lender_name = i['payload']['lender']
    borrower_name = i['payload']['borrower']
    lender = users.find { |u| u['name'] == lender_name }
    borrower = users.find { |u| u['name'] == borrower_name }
    amount = i['payload']['amount']

    inf = 1.0 / 0.0

    canonicalise = ->(u) {
      (u['owed_by'].keys & u['owes'].keys).each { |k|
        case u['owed_by'][k] <=> u['owes'][k]
        when 0
          u['owes'].delete(k)
          u['owed_by'].delete(k)
        when (-inf...0)
          u['owes'][k] -= u['owed_by'][k]
          u['owed_by'].delete(k)
        when (0..inf)
          u['owed_by'][k] -= u['owes'][k]
          u['owes'].delete(k)
        else raise 'incomparable'
        end
      }
    }

    lender['owed_by'][borrower_name] += amount
    lender['balance'] += amount
    canonicalise[lender]

    borrower['owes'][lender_name] += amount
    borrower['balance'] -= amount
    canonicalise[borrower]

    {'users' => [lender, borrower].sort_by { |u| u['name'] }}
  else raise "Unknown #{i}"
  end
}
