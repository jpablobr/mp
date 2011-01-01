# Installing as Ruby gem
# $ gem install awesome_print
require 'ap'

IRB::Irb.class_eval do
  def output_value
    ap @context.last_value
  end
end

