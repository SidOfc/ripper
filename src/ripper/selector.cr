module Ripper
  class Selector
    property :line, :name, :properties, :selectors, :parent, :indent

    @parent     : (Selector|Nil)
    @line       : String
    @indent     : Int32
    @name       : String
    @root       : Bool
    @properties : Array(String)
    @selectors  : Array(Selector)
    @expanded   : String = ""

    def initialize(@line, **options)
      @name       = @line.tr("{", "").strip
      @parent     = options[:parent]?
      @root       = options[:root]? ? true : false
      @properties = options[:properties]? || [] of String
      @selectors  = options[:selectors]?  || [] of Selector
      @indent     = @line.partition(/^\s*/)[1].size
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
