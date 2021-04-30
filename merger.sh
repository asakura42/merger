#!/bin/bash

cat << EOF > /tmp/unified.sh
#!/bin/bash

EOF

folderpath=$(readlink --canonicalize . | sed 's|$|/|')
scripts=$(fzf -m | nl)
sum=$(echo "$scripts" | wc -l)

while IFS= read -r line ; do
	scriptname=$(echo "$line" | awk '{first = $1; $1 = ""; print $0; }' | sed 's/ //')
	fullscriptpath=$(echo "$scriptname" | sed "s|^|$folderpath|")
	num=$(echo "$line" | awk '{print $1}')
	cat << EOF >> /tmp/unified.sh
#
# $scriptname #
#-------------#
_BLOCK_${num}_(){
	$(cat "$fullscriptpath" | sed '/^#!\//d')
}

EOF
done <<< "$scripts"
cat << EOF >> /tmp/unified.sh
#
# USAGE  #
#--------#
_USAGE_(){ #{{{
echo -e "
$(basename "$0") :
    $sum scripts here.
    
    List:
$(echo "$scripts" | sed 's| .*/| |')

SYNTAX :
    $(basename "$0") [NUMBER] ...
"
} #}}}
EOF

cat << EOF >> /tmp/unified.sh
#
# SCRIPT  #
#---------#
if [[ "\$1" -gt "$sum" ]] || [ -z "\$1" ] ;then
    _USAGE_
elif [[ "\$1" = "-h" ]]; then
    _USAGE_
else
    eval \$(echo "_BLOCK_\$1_ \$2 \$3 \$4")
fi
EOF
