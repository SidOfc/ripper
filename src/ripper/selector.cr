require "./property"

module Ripper
  class Selector
    property :line, :name, :properties, :selectors, :parent, :indent

    @parent     : (Selector|Nil)
    @line       : String
    @indent     : Int32
    @name       : String
    @root       : Bool
    @properties : Array(Property)
    @selectors  : Array(Selector)
    @expanded   : String = ""

    def initialize(@line, **options)
      @name       = @line.tr("{", "").strip
      @parent     = options[:parent]?
      @root       = options[:root]? ? true : false
      @properties = options[:properties]? || [] of Property
      @selectors  = options[:selectors]?  || [] of Selector
      @indent     = @line.partition(/^\s*/)[1].size
    end

    def render
      if root? || properties.none?
        output = ""
      else
        output = render_self
      end

      selectors.each { |sel| output += sel.render }
      output
    end

    def render_self
      output = expand + " {\n"

      properties.each do |prop|
        prefixed_props, prefixed_vals = prop.with_prefixes
        prefixed_props.each do |prefixed_prop|
          prefixed_vals.each do |prefixed_val|
            output += "#{prefixed_prop}: #{prefixed_val};\n"
          end
        end
      end

      output + "}\n"
    end

    def expand
      return @expanded unless @expanded.empty?

      tmp_parent = parent
      return @expanded = name unless tmp_parent
      return @expanded = name if tmp_parent.root?

      return @expanded = [tmp_parent.expand, "+", tmp_parent.name.tr("&", "").strip].join " " if name == "&&"
      return @expanded = [tmp_parent.expand, name.tr("&", "")].join if name.starts_with? "&"
      return @expanded = [name.tr("&", ""), tmp_parent.expand].join if name.ends_with? "&"
      return @expanded = name.sub "&", tmp_parent.expand            if name.includes? "&"

      @expanded = [tmp_parent.expand, name].join " "
    end

    def root?
      @root
    end
  end
end
