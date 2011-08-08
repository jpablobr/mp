user_home            = ~
bin                  = $(user_home)/bin
mp_path              = $(user_home)/.mp
mp_bin_path          = $(mp_path)/bin
mp_dotfiles_path     = $(mp_path)/dotfiles

install: link_bin link_dotfiles

link_bin:
		ln -s $(mp_bin_path) $(bin)
		touch link_bin

link_dotfiles:
		for f in dotfiles/.?*; do if [ $$f != 'dotfiles/..' ]; then ln -s $(mp_path)/$$f ~; fi;done
		touch link_dotfiles

clean_home:
		for f in dotfiles/.?*; do test -f || -d ~/`basename $$f` && test $$f != 'dotfiles/..' && rm -fr ~/`basename $$f`; done
		rm -fr $(bin)
		touch clean_home

clean:
		rm link_bin link_dotfiles clean_home