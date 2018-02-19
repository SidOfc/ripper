require "option_parser"

module Ripper
  module Options
    extend self

    OptionParser.parse! do |cli|
      cli.banner = "Usage: ripper [file]"

      cli.on("-h", "--help", "Show this help") do
        puts cli
        exit 0
      end
    end
  end
end
