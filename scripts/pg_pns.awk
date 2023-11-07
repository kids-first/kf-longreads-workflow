#!/usr/bin/awk -f

BEGIN {
    FS="\t";
    delete PNS[0];
    pointer=1;
    PICK="NONE";
}
$1 ~ /^@PG/ {
    for (i=1; i<=NF; i++) {
        if ($i ~ /^PN:/) {
            sub(/^PN:/,"",$i);
            PNS[pointer++]=$i;
        }
    }
}
END {
    if (pointer > 1) {
        for (k in PNS) {
            if (toupper(PNS[k]) ~ /CCS/) {
                PICK="CCS";
            }
        }       
    }
    print PICK;
}
