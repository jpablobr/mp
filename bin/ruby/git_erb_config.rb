#!/usr/bin/env ruby
require 'erb'

g_conf = ".gitconfig"
erb_f  = "gitconfig.erb"
home   = File.join(ENV['HOME'], g_conf)

File.open(home,'w') { |f|  f.write ERB.new(File.read(erb_f)).result(binding) }
