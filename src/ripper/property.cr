require "./prefixed"

module Ripper
  struct Property
    property :name, :value

    @name  : String
    @value : String

    def initialize(line, **options)
      @name, @value = line.tr(";", "").strip.split(":", 2).map(&.strip)
    end

    def with_prefixes
      Prefixed[name, value]
    end
  end
end
