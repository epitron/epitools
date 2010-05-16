__DIR__ = File.dirname(__FILE__)

%w[
  basetypes 
  metaclass 
  niceprint
  string_to_proc
  permutations
  ratio
  general
].each do |mod|
  require File.join(__DIR__, "epitools", mod) 
end
