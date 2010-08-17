require 'rake'
require 'erb'

namespace :mp do
  
  desc "Sets the whole environment"
  task :install => [:dotfiles, :functions, :emacs]
  
  desc "Link dotfiles to $HOME directory"
  task :dotfiles do
    replace_all = false
    Dir.chdir("dotfiles")
    Dir['*'].each do |file|
      dot_file = f_gsub(file)
      next if %w[ README.markdown ].include? dot_file
      if File.exist?(File.join(ENV['HOME'], ".#{ dot_file }"))
        if File.identical? File.join(ENV['HOME'], ".#{ dot_file }"), ".#{ dot_file }"
          puts "identical ~/.#{ dot_file }"
        elsif replace_all
          replace_file(dot_file)
        else
          print "overwrite ~/.#{ dot_file }? [yanq] "
          case $stdin.gets.chomp
          when 'a'
            replace_all = true
            replace_file(dot_file)
          when 'y'
            replace_file(dot_file)
          when 'q'
            exit
          else
            puts "skipping ~/.#{ dot_file }"
          end
        end
      else
        link_file(file)
      end
    end
  end#dotfiles
  
  desc "Links functions to ~/bin directory"
  task :functions do
    unless Dir[ENV['HOME'] + "/bin"].count == 0 
      print "~/bin directory already exist, overwrite it? [ynq] "
      case $stdin.gets.chomp
      when 'y'
        replace_bin
      when 'q'
        exit
      else
        puts "keeping current ~/bin directory"
      end
    else
      link_functions_to_bin      
    end
  end#functions

  desc "custome .emacs.d config"
  task :emacs do
    Dir.chdir('..') if Dir.pwd =~ /dotfiles/
    unless Dir[ENV['HOME'] + "/.emacs.d"].count == 0
      print "~/.emacs.d directory already exist, overwrite it? [ynq] "
      case $stdin.gets.chomp
      when 'y'
        replace_home_emacs
      when 'q'
        exit
      else
        puts "keeping current ~/.emacs.d directory"
      end
    else
      link_emacs_to_home_emacs
    end
  end#emacs

end#mp

def replace_file(file)
  system %Q{rm -rf "$HOME/.#{ file }"}
  link_file(file)
end

def link_file(file)
  if file =~ /.erb$/
    puts "generating ~/.#{ f_gsub(file) }"
    File.open(File.join(ENV['HOME'], ".#{ f_gsub(file) }"), 'w') do |new_file|
      new_file.write ERB.new(File.read(file)).result(binding)
    end
  else
    puts "linking ~/.#{ f_gsub(file) }"
    system %Q{ln -s "$PWD/#{ f_gsub(file) }" "$HOME/.#{ f_gsub(file) }"}
  end
end

def link_functions_to_bin
  puts "linking #{ Dir['functions'] } to ~/bin directory"
  system %Q{ln -s "$PWD/#{ Dir['functions'] }" "$HOME/bin"}
end

def replace_bin
  puts "Removing current ~/bin directory"
  system %Q{rm -rf "$HOME/bin"}
  link_functions_to_bin
end

def f_gsub(f)
  f.to_s.gsub(%r((dotfiles\/)|(.erb)), '')
end

def link_emacs_to_home_emacs
  system %Q{ git clone git@github.com:jpablobr/emacs.d.git }
  system %Q{ cd emacs.d && ruby install.rb }
  system %Q{ ln -s "$PWD/#{ Dir['emacs.d'] }" "$HOME/.emacs.d"}
end

def replace_home_emacs
  puts "Removing current ~/.emacs.d directory"
  system %Q{rm -rf "$HOME/.emacs.d"}
  link_emacs_to_home_emacs
end
