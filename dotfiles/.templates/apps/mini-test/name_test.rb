# -*- encoding: utf-8 -*-
require 'test_helper'

class ClassTest < MiniTest::Unit::TestCase

  def setup
    @obj = Class.new
  end

  def test_method
    assert @obj
  end
end
