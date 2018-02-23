require "./prefixed"

module Ripper
  struct Property
    property :name, :value, :original

    @name     : String
    @value    : String
    @original : String = ""

    def initialize(line, **options)
      @name, @value = line.tr(";", "").strip.split(/[:\s]/, 2).map(&.strip)
    end

    def interpolate(locals = {} of String => Variable)
      @original = value if @original.empty?
      @value    = Ripper.process_vars @value, locals
      self
    end

    def interpolated?
      !original.empty?
    end

    def with_prefixes
      Prefixed[name, value]
    end
  end
end
