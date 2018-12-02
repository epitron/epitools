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
# Load the things that can't be autoloaded
#
%w[
  core_ext
  colored
  clitools
  numwords
].each do |mod|
  require_wrapper.call mod
end

