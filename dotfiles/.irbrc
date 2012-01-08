# -*- mode: ruby -*-
begin
  require 'irbtools'
rescue LoadError
  $stderr.puts "Please install 'irbtools' or add it to your Gemfile"
end

class Object
  # Return a list of methods defined locally for a particular object.  Useful
  # for seeing what it does whilst losing all the guff that's implemented
  # by its parents (eg Object).
  def local_methods(obj = self)
    (obj.methods - obj.class.superclass.instance_methods).sort
  end
end

# Log to STDOUT if in Rails
if Object.const_defined?('ActiveRecord')
  require 'logger'
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end
