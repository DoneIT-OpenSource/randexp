dir = File.dirname(__FILE__)

%W(array integer range regexp).each do |file_name|
  require File.join(dir, 'core_ext', file_name)
end
