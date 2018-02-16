require "./prefixed"

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
      result = [] of String

      return result unless val = value

      tmp_name = name + ": " + val + ";"

      if PREFIXED.includes? name
        PREFIXES.each_with_object result do |prefix|
          result << "-#{prefix}-#{tmp_name}"
        end
      end

      result << tmp_name
      result
    end
  end
end
