require "./ripper/version"
require "./ripper/html_tags"

require "./ripper/options"
require "./ripper/selector"
require "./ripper/property"

module Ripper
  extend self

  def process_vars(line, vars = {} of String => String)
    line.gsub(/\$[^\s]+/) { |m|  vars[m]? || "-ripper-missing(#{m})" }
  end

  def parse(content)
    root    = Selector.new ""
    parents = [root] of Selector
    commas  = [] of Selector
    vars    = {} of String => String

    content.split("\n").each do |line|
      next if line.empty?

      case line_type line
      when :selector
        previous = parents.last
        current  = Selector.new line

        if line.ends_with? ","
          commas << current
          next
        end

        if current.indent > previous.indent
          parents            << current
          previous.selectors << current
        else
          loop do
            if parents.empty? || current.indent > previous.indent
              parents            += parents.empty? ? [root, current] : [previous, current]
              previous.selectors << current
              break
            end

            previous = parents.pop
          end
        end

        if commas.any?
          current.commas = commas.map do |comma|
            comma.target       =  current
            previous.selectors << comma
            comma.name
          end

          commas = [] of Selector
        end
      when :property
        parents.last.properties << Property.new process_vars line, vars
      when :variable
        key, value = line.strip.split " ", 2
        vars[key] = value
      end
    end

    root
  end

  def line_type(line : String)
    return :selector if line =~ /^\s*[+&@#.]/ || HTML_TAGS.includes?(line.strip.split(' ').first.downcase)
    return :property if line =~ /^\s*[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :variable if line =~ /^\s*\$[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :line
  end
end

tree = Ripper.parse ARGF.gets_to_end
sel  = Ripper::Selector.new ""

# puts sel.expand [".woohoo", ".there &", "+ &"]
# puts sel.expand [".there", "&&"]

puts tree.render
