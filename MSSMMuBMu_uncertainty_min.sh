#!/bin/sh

[ $# -lt 1 ] && {
    echo "Usage: $0 --slha-input-file=<input-file>"
    exit 1
}

input=-
output_block=MASS
output_entry=25
scale_block=SMINPUTS
scale_entry=0

if test $# -gt 0 ; then
    while test ! "x$1" = "x" ; do
        case "$1" in
            -*=*) optarg=`echo "$1" | sed 's/[-_a-zA-Z0-9]*=//'` ;;
            *) optarg= ;;
        esac
        case $1 in
            --slha-input-file=*)     input=$optarg ;;
            *)  echo "Invalid option '$1'. Try $0 --help" ; exit 1 ;;
        esac
        shift
    done
fi

slha_input=$(cat ${input})

mean_scale=$(echo "$slha_input" | \
                    awk -f utils/print_slha_block.awk -v block="Ms" | \
                    awk -f utils/print_slha_block_entry.awk -v entries="" | tail -n 1)

delta=$(echo "$slha_input" | ./scan_scale_FlexibleSUSY.sh models/MSSMMuBMu/run_MSSMMuBMu.x - "${scale_block}[${scale_entry}]" "${output_block}[${output_entry}]" "$mean_scale" 2 10 --min)

echo "$slha_input"
cat <<EOF
Block ${output_block}
   ${output_entry}  ${delta}
EOF
