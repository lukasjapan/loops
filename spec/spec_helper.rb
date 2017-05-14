require 'simplecov'
require 'coveralls'

formatter = [
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatter)
SimpleCov.start
