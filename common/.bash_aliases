# Allow aliases to be sudo'd
alias sudo='sudo '
# Make ls a little more friendly
alias la='ls -AgGvLhNp --group-directories-first'
# Create a single update alias that will do all the things
alias update='echo -e "APT Update:\n" && sudo apt update -y && echo -e "\nAPT Full Upgrade:\n" && sudo apt full-upgrade -y && echo -e "\nAPT Autoremove:\n" && sudo apt autoremove -y && echo -e "\nAPT Clean:\n" && sudo apt clean -y'
# Can't ever remember ncdu, so alias it up a bit
alias treesize='sudo ncdu --color dark -x'
# Fastfetch is the new neofetch
alias neofetch='fastfetch'
