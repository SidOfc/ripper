module Ripper
  struct Property
    property :name, :value

    @line  : String
    @name  : String
    @value : (String|Nil)

    def initialize(@line, **options)
      line = @line.tr(";", "").strip.split ":", 2

      @name  = line[0].strip
      @value = line[1]? && line[1].strip
    end

    def with_prefixes
      return [] of String unless val = value

      [name + ": " + val + ";"]
    end
  end
end
