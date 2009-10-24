require 'rubygems'
require 'test/unit'
require 'diff/lcs'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'caligrafo'

class String
  def first_diff(other)
    self.diff(other).first.first.position rescue nil
  end
end

class Test::Unit::TestCase
  def assert_equal_files(expected, given)
    expected = File.new(expected, 'r') if expected.is_a? String
    given    = File.new(given, 'r')    if given.is_a? String

    expected_text = expected.read
    given_text    = given.read

    lines_of_given_text = given_text.lines.to_a
  
    expected_text.each_with_index do |line, index|
      begin
        assert_equal line, lines_of_given_text[index]
      rescue Test::Unit::AssertionFailedError => e
        column = Diff::LCS.diff(line, lines_of_given_text[index]).first.first.position + 1
        raise Test::Unit::AssertionFailedError, "Line #{index + 1} dont match on column #{column}:\n#{e.message}"
      end
    end
  end
end
