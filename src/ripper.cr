require "./ripper/*"

module Ripper
  extend self

  def parse(content : String)
    root            = Selector.new "", root: true
    last_selector   = root
    last_sel_indent = 0

    content.split("\n").each do |line|
      next if line.empty?

      case line_type line
      when :selector
        current = Selector.new line

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
        last_selector.properties << line.strip.tr ";", ""
      when :comment, :close_bracket
      end
    end

    format root
  end

  def format(selector : Selector)
    result = ""

    unless selector.root? || selector.properties.none?
      result += selector.expand + " {\n"
      selector.properties.each do |prop|
        result += "  " + prop + ";\n"
      end
      result += "}\n"
    end

    if (selector.selectors.any?)
      selector.selectors.each do |selector|
        result += format selector
      end
    end

    result
  end

  def line_type(line : String)
    return :close_bracket if line =~ /^\s*\}/
    return :comment       if line =~ /^(?:#\s|\s*\/\*|\/\/)/
    return :selector      if line =~ /^\s*[&#.]/ || HTML_TAGS.includes? line.strip.split(' ')[0].downcase
    :property
  end
end

# puts Ripper::HTML_TAGS

SAMPLE = File.read File.join(__DIR__, "../", "spec", "files", "input.rip")
puts Ripper.parse SAMPLE

