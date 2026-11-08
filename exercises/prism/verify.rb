require 'json'
require_relative '../../verify'

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

def first_hit(y0, x0, heading_deg, prisms)
  heading_rad = Math::PI * heading_deg / 180
  vx = Math.cos(heading_rad)
  vy = Math.sin(heading_rad)
  prisms_in_path = prisms.select { |prism|
    dx = prism['x'] - x0
    dy = prism['y'] - y0
    # 0.001 has been known to be too strict
    (vx * dy - vy * dx).abs < 0.0011 && vx * dx + vy * dy > 0
  }
  prisms_in_path.min_by { |prism|
    dx = prism['x'] - x0
    dy = prism['y'] - y0
    vx * dx + vy * dy
  }
end

verify(json['cases'], property: 'findSequence') { |i, _|
  hits = []
  x = i['start']['x']
  y = i['start']['y']
  heading = i['start']['angle']

  while (prism = first_hit(y, x, heading, i['prisms']))
    hits << prism['id']
    y = prism['y']
    x = prism['x']
    heading += prism['angle']
  end

  {'sequence' => hits.freeze}.freeze
}
