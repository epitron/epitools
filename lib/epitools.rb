__DIR__ = File.dirname(__FILE__)

require_wrapper = proc do |mod|
  begin
    require File.join(__DIR__, "epitools", mod)
  rescue LoadError => e
    puts "* Error loading epitools/#{mod}: #{e}"
  end
end

%w[
  metaclass 
  basetypes 
  niceprint
  string_to_proc
  ratio
  path
  zopen
  colored
  clitools
].each do |mod|
  require_wrapper.call mod
end
