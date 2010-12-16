# DOTFILES #

These are config files to set up a system the way I like it.

## Environment ##

I primarily use zsh, but this includes some older bash files as well. If you
would like to switch to zsh, you can do so with the following command.

  chsh -s /bin/zsh

## Features ##

I normally place all of my coding projects in ~/code, so this directory can
easily be accessed (and tab completed) with the "c" command.

  c project<tab>

To speed things up, the results are cached in local .rake_tasks~ and
.cap_tasks~. It is smart enough to expire the cache automatically in most cases,
but you can simply remove the files to flush the cache.

If there are some shell configuration settings which you want secure or specific
to one system, place it into a ~/.localrc file. This will be loaded
automatically if it exists.

There are several features enabled in Ruby's irb including history and
completion. Many convenience methods are added as well such as "ri" which can be
used to get inline documentation in IRB. See irbrc and railsrc files for
details.

This is my HOME, including shell environment, vim configuration, and other misc
dotfiles and scripts.

## Background ##

I don't suggest using this as some kind of prefab home environment (although
that's certainly possible). Look through the stuff and take what you find useful
with copy and paste or by copying specific files and directories into your own
home - such is the tradition of UNIX home directories.
