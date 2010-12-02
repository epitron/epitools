$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

p $:

require 'rspec'
require 'epitools'

Rspec.configure do |c|
  c.mock_with :rspec
end
