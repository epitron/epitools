require 'pp'
require File.join(File.dirname(__FILE__), "epitools", "minimal")

## Pretty loading messages
require_wrapper = proc do |mod|
  #p [:loading, mod]
  begin
    require File.join(__DIR__, "epitools", mod)
  rescue LoadError => e
    puts "* Error loading epitools/#{mod}: #{e}"
  end
end

#
# Make all the modules autoload, and require all the monkeypatches
#
%w[
  core_ext 
  zopen
  colored
  clitools
  numwords
].each do |mod|
  require_wrapper.call mod
end

