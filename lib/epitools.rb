__DIR__ = File.dirname(__FILE__)

%w[
  metaclass 
  basetypes 
  niceprint
  string_to_proc
  permutations
  ratio
  zopen
].each do |mod|
  require File.join(__DIR__, "epitools", mod) 
end
