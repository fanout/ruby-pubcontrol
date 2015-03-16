require 'item'
require 'format'
require 'minitest/autorun'

class TestFormatSubClass < Format
  def name
    return 'name'
  end

  def export
    return {'body' => 'bodyvalue'}
  end
end

class TestFormatSubClass2 < Format
  def name
    return 'name'
  end

  def export
    return {'body' => 'bodyvalue'}
  end
end

class TestItem < Minitest::Test
  def test_initialize
    item = Item.new([0, 'format'], 'id', 'prev-id')
    assert_equal(item.instance_variable_get(:@id), 'id');
    assert_equal(item.instance_variable_get(:@prev_id), 'prev-id');
    assert_equal(item.instance_variable_get(:@formats), [0, 'format']);
    format = TestFormatSubClass.new
    format2 = TestFormatSubClass2.new
    item = Item.new([format, format2])
    assert_equal(item.instance_variable_get(:@formats), [format, format2]);
    item = Item.new(format)
    assert_equal(item.instance_variable_get(:@formats), [format]);
  end

  def test_export
    format = TestFormatSubClass.new
    out =  Item.new(format, 'id', 'prev-id').export
    assert_equal(out['name'], { 'body' => 'bodyvalue' })
    assert_equal(out['id'], 'id')
    assert_equal(out['prev-id'], 'prev-id')
    out = Item.new(format).export
    assert(out.key?('id') == false)
    assert(out.key?('prev-id') == false)
  end

  def test_export_same_format_type
    item = Item.new([TestFormatSubClass.new, TestFormatSubClass.new])
    assert_raises RuntimeError do
        item.export
    end
  end
end
