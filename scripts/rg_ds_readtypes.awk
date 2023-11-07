#!/usr/bin/awk -f

BEGIN {
    FS="\t";
    delete RTS[0];
    pointer=1;
    PICK="NONE";
}
$1 ~ /^@RG/ {
    for (i=1; i<=NF; i++) {
        if ($i ~ /^DS:/) {
            sub(/^DS:/,"", $i);
            split($i, a, ";");
            for (j in a) {
                if (a[j] ~ /^READTYPE/) {
                    split(a[j], b, "=");
                    RTS[pointer++]=b[2];
                }
            }
        }
    }
}
END {
    if (pointer > 1) {
        for (k in RTS) {
            if (PICK != "NONE" && PICK != RTS[k]) {
                PICK="MIXED";
            } else {
                PICK=RTS[k];
            }
        }  
    }
    print PICK;
}
