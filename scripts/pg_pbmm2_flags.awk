#!/usr/bin/awk -f

BEGIN {
    FS="\t";
    PICK="NONE"
}
$1 ~ /^@PG/ && $0 ~ /ID:pbmm2/ {
    for (i=1; i<=NF; i++) {
        if ($i ~ /^CL:/) {
            sub(/^CL:/,"",$i);
            split($i, a, " ");
            for (j in a) {
                if (a[j] == "--preset") {
                    PICK=a[++j];
                }
            }
        }
    }
}
END {
    print PICK;
}
