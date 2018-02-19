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

    def render(locals = {} of String => String)
      if root? || statement? || properties.none?
        output = ""
      else
        output = render_self locals
      end

      selectors.each { |sel| output += statement? ? parse_statement : sel.render(locals) }
      output
    end

    def render_self(locals = {} of String => String)
      output = expand.gsub(/\$[a-z_-]+[\w\-]*/i) { |n| locals[n[1..-1]]? || n } + " {\n"

      properties.each do |prop|
        prefixed_props, prefixed_vals = prop.with_prefixes
        prefixed_props.each do |prefixed_prop|
          prefixed_vals.each do |prefixed_val|
            output += "  #{prefixed_prop}: #{prefixed_val};\n"
          end
        end
      end

      output + "}\n"
    end

    def expand
      return @expanded unless @expanded.empty?

      return @expanded = name unless tmp_parent = parent
      return @expanded = name unless tmp_parent = tmp_parent.parent if tmp_parent.statement?

      return @expanded = name if tmp_parent.root?
      return @expanded = [tmp_parent.expand, "+", tmp_parent.name.tr("&", "").strip].join " " if name == "&&"
      return @expanded = [tmp_parent.expand, name.tr("&", "")].join if name.starts_with? "&"
      return @expanded = [name.tr("&", ""), tmp_parent.expand].join if name.ends_with? "&"
      return @expanded = name.sub "&", tmp_parent.expand            if name.includes? "&"

      @expanded = [tmp_parent.expand, name].join " "
    end

    def statement?
      name.starts_with? "@"
    end

    def parse_statement
      parts = name.split /\s+/, 4

      case parts.first
      when "@each"
        local = parts[1]
        seq   = parts[3].lstrip('[').rstrip(']').split(/,\s*/)
        res   = ""

        seq.each do |val|
          selectors.each { |sel| res += sel.render({local => val}) }
        end

        return res
      end

      ""
    end

    def root?
      @root
    end
  end
end
