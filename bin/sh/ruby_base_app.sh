#!/usr/bin/env bash

old_IFS="$IFS"
IFS=:
  echo "-------------------------------------------------------------------------"
  echo "RUBY APP STARTER"
  echo "----------------"
  echo "Creates the skeleton for a basic ruby app."
  echo "---"
  echo "Please enter the name for your app:"
  read app_name
IFS=$old_IFS

app_name_main="require '...'\n"

spec_helper="require File.dirname(__FILE__) + '/lib'\n
require 'rubygems'"

app_spec="require File.dirname(__FILE__) + '/spec_helper'\n
describe $app_name do\n
\n
  it '...' do\n
  end\n
\n
end\n"

gem_file="source :rubygems\n
\n
group :development, :test do\n
  gem 'rspec'\n
end\n"

git_ignore="*.sw?\n
.bundle\n"

app_readme="* $app_name README.mdn/"

app_rvmrc="#!/usr/bin/env bash\n
ruby_string='ruby-1.9.2-p136'\n
gemset_name=\"$app_name\"\n"

mkdir "$app_name"
mkdir "$app_name/spec"
touch "$app_name/$app_name.rb"
touch "$app_name/spec/spec_helper.rb"
touch "$app_name/spec/$app_name_spec.rb"
touch "$app_name/Gemfile"
touch "$app_name/.gitignore"
touch "$app_name/README.md"
touch "$app_name/.rvmrc"

echo $app_name_main > "$app_name/$app_name.rb"
echo $spec_helper > "$app_name/spec/spec_helper.rb"
echo $app_spec > "$app_name/spec/$app_name""_spec.rb"
echo $gem_file > "$app_name/Gemfile"
echo $git_ignore > "$app_name/.gitignore"
echo $app_readme  > "$app_name/README.md"
echo $app_rvmrc  > "$app_name/.rvmrc"
