require "./ripper/version"
require "./ripper/html_tags"

require "./ripper/options"
require "./ripper/selector"
require "./ripper/property"
require "./ripper/variable"

module Ripper
  extend self

  def parse(content)
    root    = Selector.new ""
    parents = [root] of Selector
    commas  = [] of Selector
    env     = {} of String => Variable

    content.split("\n").each do |line|
      next if line.empty?

      case line_type line
      when :selector
        previous = parents.last
        current  = Selector.new line

        if !line[1..-2].includes?(",") && line.ends_with? ","
          commas << current
          next
        elsif !current.statement && line.includes? ","
          commas  = line.split(/,\s*/).map { |comma| Selector.new comma }
          next commas.pop if commas.last.name.empty?
          current = commas.pop

          if commas.any?
            current.indent = commas.first.indent
          end
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
        if commas.any?
          current = commas.pop
          current.commas = commas.map do |comma|
            comma.target           =  current
            parents.last.selectors << comma
            comma.name
          end

          parents.last.selectors << current
          parents << current
          commas = [] of Selector
        end

        parents.last.properties << Property.new line
      when :variable
        key, value = line.strip.split " ", 2
        env[key]   = Variable.new key, value
      end
    end

    {root, env}
  end

  def line_type(line : String)
    return :selector if line =~ /^\s*[+&@#.]/ || HTML_TAGS.includes?(line.strip.split(' ').first.downcase)
    return :property if line =~ /^\s*[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :variable if line =~ /^\s*\$[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :unknown
  end

  def process_vars(input, env = {String => Variable})
    input.gsub(/\$[^\s,]+/) do |match|
      if var = env[match]?
        var.value
      else
        "-ripper-unknown(#{match})"
      end
    end
  end
end

tree, env = Ripper.parse ARGF.gets_to_end

# pp tree
puts tree.render [] of String, env
