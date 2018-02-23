require "./property"
require "./variable"

module Ripper
  class Selector
    property :line, :name, :properties, :selectors, :indent, :target, :commas, :statement

    @target     : (Selector|Nil)
    @name       = ""
    @indent     = 0
    @commas     = [] of String
    @properties = [] of Property
    @selectors  = [] of Selector
    @statement  = false

    def initialize(line, **options)
      @indent     = line.partition(/^\s*/)[1].size
      @name       = line.lstrip.rstrip "{, "
      @statement  = name.starts_with? "@"
      @target     = options[:target]?
      @properties = options[:properties]? || [] of Property
      @selectors  = options[:selectors]?  || [] of Selector
    end

    def target
      @target || self
    end

    def render(names = [] of String, env = {String => Variable})
      targets = names + [name]
      content = target == self ? target.render_self(targets, env) : ""

      content + target.selectors.map(&.render(targets, env).as(String)).join
    end

    def render_self(names = [] of String, env = {String => Variable})
      return "" if target.properties.none? || names.empty?
      output = (commas + [names.last]).map { |n| expand(names[0..-2] + [n], env) }.join(",\n") + " {\n"

      target.properties.each do |prop|
        prefixed_props, prefixed_vals = prop.interpolate(env).with_prefixes
        prefixed_props.each do |prefixed_prop|
          prefixed_vals.each do |prefixed_val|
            output += "  #{prefixed_prop}: #{prefixed_val};\n"
          end
        end
      end

      output + "}\n"
    end

    def expand(names = [] of String, env = {String => Variable})
      selector = ""
      ending   = ""

      names.each do |name|
        tmp = name
        case tmp
        when /^(?:&?\s*\+\s*&|&&)$/
          selector += " + #{ending.strip}"
        when /^&/
          selector += ending = tmp.tr "&", ""
        when /&$/
          ending   = tmp.tr "&", ""
          selector = ending + selector.lstrip
        when /&/
          selector = tmp.sub "&", selector.strip
          ending   = selector.split(" ").last
        else
          selector += ending = " #{tmp}"
        end
      end

      selector.strip
    end
  end
end
