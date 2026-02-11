# Define a single Powerlevel10k option to convince the wizard we're all set
POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true

# Since this is also used on Darwin hosts, alias "fdfind" to "fd"
command -v fdfind > /dev/null || alias fdfind="fd"

# Find all .sh files in ~/.zshrc.d
FILES_STR=$(fdfind --glob '*.sh' ~/.zshrc.d)

# 'tr' is a find-and-replace utility.
# Outer () will convert the output of $() to array.
FILES=($(echo $FILES_STR | tr '\n' ' '))
for FILE in $FILES; do
    source $FILE
done
