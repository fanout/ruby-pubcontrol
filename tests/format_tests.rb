require 'format'
require 'minitest/autorun'

class TestFormatSubClass < Format
  def name
    return 'test_name'
  end

  def export
    return 'test_export'
  end
end

class TestFormat < Minitest::Test
  def test_inheritance
    format = Format.new
    assert_raises( NotImplementedError ) { format.name }
    assert_raises( NotImplementedError ) { format.export }
    subclass = TestFormatSubClass.new
    assert_equal(subclass.name, 'test_name')
    assert_equal(subclass.export, 'test_export')
  end
end
