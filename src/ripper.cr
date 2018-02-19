require "./ripper/version"
require "./ripper/html_tags"

require "./ripper/options"
require "./ripper/selector"
require "./ripper/property"

module Ripper
  extend self

  @@vars = {} of String => String

  def vars
    @@vars
  end

  def var(name)
    @@vars[name]?
  end

  def var(name, value)
    @@vars[name] = value
  end

  def process_vars(line)
    line.gsub(/\$[a-z_\-][\w\-]*/i) { |n| var(n) || n }
  end

  def parse(content)
    root          = Selector.new "", root: true
    last_selector = root

    content.split("\n").each do |line|
      case line_type line
      when :selector
        current = Selector.new process_vars(line)

        if current.indent > last_selector.indent
          current.parent = last_selector
          last_selector.selectors << current
        elsif current.indent <= last_selector.indent
          if pls = last_selector.parent
            loop do
              if pls.root? || current.indent > pls.indent
                current.parent = pls
                pls.selectors << current
                break
              end

              break unless pls = pls.parent
            end
          else
            current.parent = root
            root.selectors << current
          end
        end

        last_selector = current
      when :property
        last_selector.properties << Property.new process_vars(line)
      when :variable
        key, value = line.split(/\s+/).map(&.strip)
        var key, value
      end
    end

    root.render
  end

  def line_type(line : String)
    return :selector if line =~ /^\s*[&@#.]/ || HTML_TAGS.includes? line.strip.split(' ').first.downcase
    return :property if line =~ /^\s*[a-z_-][\w\-]*[:\s][^;]+;?/i
    return :variable if line =~ /^\s*\$[a-z_][\w\-]*\s+[^;]+;?/i
  end
end

puts Ripper.parse ARGF.gets_to_end
