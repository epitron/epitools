__DIR__ = File.dirname(__FILE__)

%w[basetypes metaclass niceprint].each { |r| require File.join(__DIR__, "epitools", r) }
