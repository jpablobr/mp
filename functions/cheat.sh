#gem install cheat

# Cache and complete Cheats
if [ ! -r ~/.cheats ]; then
  echo "Rebuilding Cheat cache..."
  cheat sheets | egrep '^ ' | awk '{print $1}' > ~/.cheats
fi
complete -W "$(cat ~/.cheats)" cheat