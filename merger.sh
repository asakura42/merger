#!/bin/bash

cat << EOF > /tmp/unified.sh
#!/bin/bash

EOF

folderpath=$(readlink --canonicalize . | sed 's|$|/|')
scripts=$(fzf -m | nl)
sum=$(echo "$scripts" | wc -l)


# Assign custom flags
read -p "Do you want to create custom flags for scripts? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
        tmp=$(mktemp)
        echo "Assign flags when needed with TAB between like

1 script.sh     -c
2 cringe.sh
3 test.sh       -t

Press enter to continue"
read
        echo "$scripts" | sed 's/^ *//' > $tmp
        "$EDITOR" "$tmp"
        flags=$(awk -F '\t' '$3' "$tmp")
        while IFS= read -r line ; do
                arg=$(echo -e "$line" | awk -F'\t' '{print $3}')
                scrnum=$(echo -e "$line"  |  awk -F'\t' '{print $1}')

                elifs="$elifs\nelif [ \"\$1\" = \"$arg\" ]; then\neval \$(echo \"_BLOCK_${scrnum}_ \\\"\$2\\\" \\\"\$3\\\" \\\"\$4\\\"\")"

        done <<< "$flags"

fi

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
$(basename "$0") contains $sum scripts:
    
    List:
$(if [ ! -z $tmp ] ; then
	cat $tmp | column -t
else
	echo "$scripts" | column -t
fi)

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
$(echo -e "$elifs")
else
    eval \$(echo "_BLOCK_\$1_ \"\$2\" \"\$3\" \"\$4\"")
fi
EOF
