require 'json'
require_relative '../../verify'

class SGF
  class ParseError < StandardError; end

  def initialize(str)
    @str = str.freeze
  end

  def node(pos, paren_required: false)
    raise ParseError, "need paren at #{pos} not #{@str[pos]}" if paren_required && @str[pos] != ?(

    need_close_paren = false
    if @str[pos] == ?(
      pos += 1
      need_close_paren = true
    end

    raise ParseError, "need semicolon at #{pos} not #{@str[pos]}" if @str[pos] != ?;
    pos += 1

    pos, props = properties(pos)
    children = []

    while (c = @str[pos])
      case c
      when ?;
        pos, child = node(pos)
        children << child
      when ?(
        pos, child = node(pos, paren_required: true)
        children << child
      else
        break
      end
    end

    props.freeze
    children.freeze

    if @str[pos] == ?)
      return [pos + (need_close_paren ? 1 : 0), {'properties' => props, 'children' => children}]
    end

    raise ParseError, "need ) at #{pos} not #{@str[pos]}"
  end

  def properties(pos)
    props = {}

    while (c = @str[pos])
      break unless (?A..?Z).cover?(c)

      pos, name, values = property(pos)
      props[name] = values
    end

    return [pos, props.freeze]
  end

  def property(pos)
    name = ''
    values = []

    while (c = @str[pos])
      case c
      when ?A..?Z
        name << c
        pos += 1
      when ?[
        name.freeze
        break
      when ?)
        raise ParseError, "No values for #{name} at #{pos}"
      else
        raise ParseError, "Improper name #{name}#{c} at #{pos}"
      end
    end

    while (c = @str[pos])
      break unless c == ?[
      pos, val = value(pos + 1)
      values << val
    end

    return [pos, name, values.freeze]
  end

  def value(pos)
    val = ''
    escape = false

    while (c = @str[pos])
      return [pos + 1, val.freeze] if c == ?] && !escape

      if c == ?\\ && !escape
        escape = true
      else
        val << ?\\ if escape && c == ?n
        if escape && c == ?t
          val << ' '
        else
          val << c
        end
        escape = false
      end
      pos += 1
    end

    raise ParseError, "No end to value #{val}"
  end
end

json = JSON.parse(File.read(File.join(__dir__, 'canonical-data.json')))

verify(json['cases'], property: 'parse') { |i, c|
  pos, node = SGF.new(i['encoded']).node(0, paren_required: true)
  raise 'Incomplete parse' unless pos == i['encoded'].size
  node
}
