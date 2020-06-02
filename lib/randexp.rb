class Randexp
  attr_accessor :sexp

  def initialize(source)
    @sexp = Randexp::Parser[source]
  end

  def reduce
    Reducer[@sexp.dup]
  end
end

dir = File.dirname(__FILE__) + '/randexp'

%W(version core_ext dictionary parser randgen reducer).each do |file_name|
  require File.join(dir, file_name)
end

%W(female_names male_names real_name).each do |file_name|
  require File.join(dir, 'wordlists', file_name)
end
