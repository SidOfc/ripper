require "./property"

module Ripper
  class Selector
    property :line, :name, :properties, :selectors, :indent, :target, :commas

    @target     : (Selector|Nil)
    @name       = ""
    @indent     = 0
    @commas     = [] of String
    @properties = [] of Property
    @selectors  = [] of Selector

    def initialize(line, **options)
      @name       = line.tr("{,", "").strip
      @target     = options[:target]?
      @properties = options[:properties]? || [] of Property
      @selectors  = options[:selectors]?  || [] of Selector
      @indent     = line.partition(/^\s*/)[1].size
    end

    def target
      @target || self
    end

    def render(names = [] of String)
      targets = names + [name]
      content = target == self ? target.render_self(targets) : ""

      content + target.selectors.map(&.render(targets).as(String)).join
    end

    def expand(names = [] of String)
      selector = ""
      ending   = ""

      names.each do |name|
        case name
        when /^(?:&?\s*\+\s*&|&&)$/
          selector += " + #{ending.strip}"
        when /^&/
          selector += ending = name.tr "&", ""
        when /&$/
          ending   = name.tr "&", ""
          selector = ending + selector.lstrip
        when /&/
          selector = name.sub "&", selector.strip
          ending   = selector.split(" ").last
        else
          selector += ending = " #{name}"
        end
      end

      selector.strip
    end

    def render_self(names = [] of String)
      return "" if target.properties.none? || names.empty?
      sub    = expand names[0..-2]
      output = (commas + [names.last]).map { |n| expand(names[0..-2] + [n]) }.join(",\n") + " {\n"

      target.properties.each do |prop|
        prefixed_props, prefixed_vals = prop.with_prefixes
        prefixed_props.each do |prefixed_prop|
          prefixed_vals.each do |prefixed_val|
            output += "  #{prefixed_prop}: #{prefixed_val};\n"
          end
        end
      end

      output + "}\n"
    end
  end
end
