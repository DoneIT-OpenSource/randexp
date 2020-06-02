class Randexp
  class Parser
    def self.parse(source)
      case
      when source =~ /^(.*)\\(.)$/                                      # escaped /..\?/ or /..\)/
        union(parse($1), literal($2))
      when source =~ /^(.*[^\\])(\*|\*\?|\+|\+\?|\?)$/
        parse_quantified($1, $2.to_sym)                                 # ends with *, +, or ?: /(..)?/
      when source =~ /^(.*)\{(\d*)\,(\d+)\}$/
        parse_quantified($1, ($2.to_i)..($3.to_i))                      # ends with a range: /(..){..,..}/
      when source =~ /^(.*)\{(\d+)\}$/
        parse_quantified($1, $2.to_i)                                   # ends with a range: /..(..){..}/
      when source =~ /^.+?[^\\]\)+$/                                    # /..)/
        i = simplifi(source)
        if i >= 0
          s2 = source[i+1..-2].gsub(/^\?:/, '')
          if i.zero?
            union(parse(s2))                                            # union /(..)/
          elsif source[i-1] != '|' || source[i-2] == '\\'
            union(parse(source[0...i]), union(parse(s2)))               # union /..(..)/
          elsif i - 2 >= 0 && source[i-1] == '|' && source[i-2] != '\\'
            intersection(parse(source[0..i-2]), union(parse(s2)))       # intersection /..|(..)/
          end
        else
          fail SyntaxError, 'count "(" not eq count ")"'
        end
      when source =~ /^(.+)\|(.+?[^\]])$/ && $1[-1] != '\\' && balanced?($2)
        intersection(parse($1), parse($2))                              # implied intersection: /..|../
      when source =~ /^(.*)\[\:(.*)\:\]$/
        union(parse($1), random($2))                                    # custom random: /[:word:]/
      when source =~ /^.+\[.*[^\\]\]$/ && (i = simplifi(source)) > 0
        if source[i-1] == '|' && source[i-2] != '\\'
          intersection(parse(source[0..i-2]), parse(source[i..-1]))     # intersection: /..|[0-9a-zA-Z]/
        else
          union(parse(source[0...i]), parse(source[i..-1]))             # range: /..[0-9a-zA-Z]/
        end
      when source =~ /^\[(\S-\S|\\.|.)(.*)\]$/
        if $2.empty?                                                    # range: /[0-9a-zA-z]/
          parse_range($1)
        else
          range(parse_range($1), parse("[#{ $2 }]"))
        end
      when source =~ /^(.*)\\([wsdc])$/
        union(parse($1), random($2))                                    # reserved random: /..\w/
      when source =~ /(.*)(.|\s)$/
        condition = $2 == '|' && source[-2] != '\\'
        union(parse($1), literal(condition ? '' : $2))                  # end with literal or space: /... /
      else
        nil
      end
    end

    def self.parse_quantified(source, multiplicity)
      if source =~ /^.+?[^\\]\)+$/
        case simplifi(source)
        when -1
          fail SyntaxError, 'count "(" not eq count ")"'                # /..(..)..)/ or /(..(..)../
        when 0
          quantify(parse(source), multiplicity)                         # /(..)+/
        else
          quantify_rhs(parse(source), multiplicity)                     # /(..)(..(..))?/
        end
      else
        quantify_rhs(parse(source), multiplicity)                       # /..(..)..{3}/
      end
    end

    def self.simplifi(str)
      return -1 if !str.is_a?(String) || str.empty? || ![')', ']'].include?(str[-1]) || str[-2] == '\\'
      limiters = %W(( [ ) ])
      limiters_count = Array.new limiters.count, 0
      limiters_count[limiters.index(str[-1])] += 1
      position = str.length - 2
      escaped = str[-1] == ']'
      repeat = true
      while position >= 0 && repeat
        if !escaped || str[position] == '[' && str[position - 1] != '\\'
          i = limiters.index(str[position])
          limiters_count[i] += 1 if i && str[position - 1] != '\\'
          repeat = limiters_count[0..1] != limiters_count[2..-1]
          escaped = str[position] == ']' && str[position - 1] != '\\'
        end
        position -= 1 if repeat
      end
      position
    end

    def self.balanced?(str)
      return false if !str.is_a?(String) || str.empty?
      limiters = %W(( [ ) ])
      limiters_count = Array.new limiters.count, 0
      escaped = false
      escaped_range = false
      str.each_char do |ch|
        if !escaped && (!escaped_range || ch == ']')
          i = limiters.index(ch)
          limiters_count[i] += 1 if i
          escaped_range = ch == '['
        end
        escaped = ch == '\\'
      end
      limiters_count[0..1] == limiters_count[2..-1]
    end

    class << self
      alias_method :[], :parse
    end

    def self.quantify_rhs(sexp, multiplicity)
      if [:union, :intersection].include?(sexp.first)
        rhs = sexp.pop
        sexp << quantify(rhs, multiplicity)
      else
        quantify(sexp, multiplicity)
      end
    end

    def self.quantify(lhs, sym)
      [:quantify, lhs, sym]
    end

    def self.union(lhs, *rhs)
      if lhs.nil?
        union(*rhs)
      elsif rhs.empty?
        lhs
      elsif lhs.first == :union
        rhs.each {|s| lhs << s}
        lhs
      else
        [:union, lhs, *rhs]
      end
    end

    def self.intersection(lhs, rhs)
      if rhs.first == :intersection
        [:intersection, lhs] + rhs[1..-1]
      else
        [:intersection, lhs, rhs]
      end
    end

    def self.random(char)
      [:random, char.to_sym]
    end

    def self.literal(word)
      [:literal, word]
    end

    def self.range(lhs, rhs)
      if lhs.first == :range && rhs.first == :range
        lhs + rhs[1..-1]
      elsif lhs.first == :range
        [:range, rhs] + lhs[1..-1]
      elsif rhs.first == :range
        [:range, lhs] + rhs[1..-1]
      else
        [:range, lhs, rhs]
      end
    end

    def self.parse_range(arg)
      el = arg.scan(/^(\S)-(\S)$/).flatten
      if !el.empty?
        (el.first..el.last).to_a.map { |i| literal(i) }.unshift(:range)
      else
        literal(arg)
      end
    end
  end
end
