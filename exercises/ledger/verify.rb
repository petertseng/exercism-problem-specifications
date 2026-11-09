require 'date'
require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def fmt_money(cents, thousands_sep, cents_sep, sign_f)
  neg = cents < 0
  dollars, cents = cents.abs.divmod(100)
  dollars = dollars.to_s.reverse.each_char.each_slice(3).map(&:join).join(thousands_sep).reverse
  sign_f[neg, "#{dollars}#{cents_sep}#{'%02d' % cents}"]
end

def trunc(s, len)
  s.size <= len ? s.ljust(len) : s[0, len - 3] + '...'
end

verify(json['cases'], property: 'formatEntries') { |i, _|
  [{
    'en_US' => 'Date       | Description               | Change       ',
    'nl_NL'=>  'Datum      | Omschrijving              | Verandering  ',
  }.fetch(i['locale'])] + i['entries'].sort_by { |e| [e['date'], e['description'], e['amountInCents']] }.map { |e|
    sym = {'USD' => ?$, 'EUR' => ?€}.fetch(i['currency'])
    Date.parse(e['date']).strftime({
      'en_US' => '%m/%d/%Y',
      'nl_NL'=>  '%d-%m-%Y',
    }.fetch(i['locale'])) + ' | ' + trunc(e['description'], 25) + ' | ' + fmt_money(e['amountInCents'], *{
      'en_US' => [?,, ?., ->(neg, amt) { neg ? "(#{sym}#{amt})" : "#{sym}#{amt} " }],
      'nl_NL'=>  [?., ?,, ->(neg, amt) { "#{sym} #{?- if neg}#{amt} " }],
    }.fetch(i['locale'])).rjust(13)
  }
}
