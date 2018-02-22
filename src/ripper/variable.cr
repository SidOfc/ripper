module Ripper
  struct Variable
    property :name, :value, :type, :vars

    @name  : String
    @value : String
    @type  : Symbol

    def initialize(@name, @value)
      @value = @value.gsub(/\s+/, " ").strip
      @type  = case value
               when /^\[[^(?<=\\)\]]+\]$/ then :array
               when /^\{[^(?<=\\)\}]+\}$/ then :hash
               when /^\d+$/               then :integer
               when /^\d+\.\d+$/          then :float
               when /^(?:true|false)$/    then :boolean
               else                            :string
               end
    end
  end
end
