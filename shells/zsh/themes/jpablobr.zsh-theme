# user, host, full path, and time/date
# on two lines for easier vgrepping
# entry in a nice long thread on the Arch Linux forums: http://bbs.archlinux.org/viewtopic.php?pid=521888#p521888
# Time  - %{\e[0;37m%}%B[%b%{\e[0;35m%}'%D{"%a %b %d, %I:%M"}%b$'%{\e[0;37m%}%B]%b%{\e[0m%}

local smiley="%(?,%{$fg[green]%}:%)%{$reset_color%},%{$fg[red]%}:(%{$reset_color%})"
PROMPT=╭─$'%{\e[0;37m%}%B[%b%{\e[0m%}%{\e[0;35m%}%n%{\e[1;35m%}@%{\e[0m%}%{\e[0;35m%}%m%{\e[0;37m%}%B]%b%{\e[0m%} - %b%{\e[0;37m%}%B[%b%{\e[0;35m%}%~%{\e[0;37m%}%B]%b%{\e[0m%}
╰─${blue_op}${smiley}${blue_cp} %# <$(git_prompt_info)>%{\e[0m%}%b '
local cur_cmd="${blue_op}%_${blue_cp} "
PROMPT2='${cur_cmd}> '