# Paths
user_home            = ~
bin                  = $(user_home)/bin
mp_path              = $(user_home)/.my-precious
mp_dotfiles_path     = $(mp_path)/dotfiles
mp_bin_path          = $(mp_path)/bin

mp_dotfiles = .ackrc														\
							.aprc															\
							.autotest													\
							.bash_profile											\
							.bashrc														\
							.caprc														\
							.conkerorrc												\
							.dircolors												\
							.editrc														\
							.folders													\
							.gemrc														\
							.gitshrc													\
							.htoprc														\
							.inputrc													\
							.irbrc														\
							.irbrc.d													\
							.lesskey													\
							.railsrc													\
							.railsrc.d												\
							.rdebugrc													\
							.rvmrc														\
							.sake															\
							.screenrc													\
							.shoulda.conf											\
							.templates												\
							.tmux.conf

link_bin_dir          = ln -s $(mp_bin_path) $(bin)
mp_dotfiles_full_path = $(mp_dotfiles:%=$(mp_dotfiles_path)/%)
mp_installed_dotfiles = $(mp_dotfiles:%=$(user_home)/%)

install:
		test ! -d $(bin) && $(link_bin_dir)

		cd $(user_home); \
		ln -s $(mp_dotfiles_full_path) .;

uninstall:
		rm $(mp_installed_dotfiles); \
		rm -fr $(bin) && echo uninstalled