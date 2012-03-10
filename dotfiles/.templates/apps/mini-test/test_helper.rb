# -*- encoding: utf-8 -*-
if RUBY_VERSION < "1.9"
  require 'test/unit'
else
  require 'test/unit'
  require 'minitest/unit'
end

$TEST = true

lib_dir  = File.join(File.dirname(__FILE__), '..', 'lib')
$LOAD_PATH.unshift lib_dir, File.dirname(__FILE__)

require '{template-name}'
