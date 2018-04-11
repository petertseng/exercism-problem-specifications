require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

cases = by_property(json['cases'], %w(privateKeyIsInRange privateKeyIsRandom publicKey secret keyExchange))

verify(cases['publicKey'], property: 'publicKey') { |i, _|
  i[?g] ** i['privateKey'] % i[?p]
}

verify(cases['secret'], property: 'secret') { |i, _|
  i['theirPublicKey'] ** i['myPrivateKey'] % i[?p]
}

verify(cases['keyExchange'], property: 'keyExchange') { |i, _|
  # Nothing to really verify here, but we'll do it anyway.
  p = i[?p]
  g = i[?g]

  100.times {
    a, b = 2.times.flat_map {
      priv = rand(p - 2) + 2
      pub = g ** priv % p
      {
        priv: priv,
        pub: pub,
      }
    }

    secrets = [[a, b], [b, a]].map { |us, them|
      them[:pub] ** us[:priv] % p
    }

    raise TestFailure, "#{secrets}" unless secrets.uniq.size == 1
  }

  'secretA == secretB'
}
