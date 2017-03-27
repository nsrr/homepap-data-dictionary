require 'test_helper'
require 'colorize'

class DictionaryTest < Minitest::Test
  # This line includes all default Spout Dictionary tests
  include Spout::Tests

  # This line provides access to @variables, @forms, and @domains
  # iterators that can be used to write custom tests
  include Spout::Helpers::Iterators

  VALID_UNITS = [
    ' ', '', 'beats per minute', 'percent', 'events per hour',
    'kilograms per meters squared', 'kilograms', 'days since enrollment',
    'centimeters', 'millimeters of mercury', 'times', 'movements', 'bpm',
    'cmH2O', 'nights', '% of days', 'days', 'liters/minute', 'minutes', 'cm',
    'events per hour', '%', 'years', 'hours', 'events', 'seconds', 'mmHG', 'kg',
    'attempts', 'items'
  ] # Example ['mmHG', 'bpm', 'readings', 'minutes', '%', 'hours', 'MET']

  @variables.select { |v| %w(numeric integer).include?(v.type) }.each do |variable|
    define_method("test_units: #{variable.path}") do
      message = "\"#{variable.units}\"".colorize(:red) + " invalid units.\n" +
                "             Valid types: " +
                VALID_UNITS.sort_by(&:to_s).collect { |u| u.inspect.colorize(:white) }.join(', ')
      assert VALID_UNITS.include?(variable.units), message
    end
  end
end
