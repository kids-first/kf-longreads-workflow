#!/usr/bin/awk -f

BEGIN {
    FS="\t";
    delete QUALS[0];
    pointer=1;
    PICK="NONE";
    NZEROS=0;
    NBASES=0;
    NCCS=0;
    NCLR=0;
}
$1 !~ /^@/ {
    NBASES=length($11);
    gsub(/[^\!]/,"",$11);
    NZEROS=length($11);
    QUALS[pointer++]=NZEROS/NBASES;
}
END {
    if (pointer > 1) {
        for (k in QUALS) {
            if (QUALS[k] > 0.9) {
                NCLR++;
            } else {
                NCCS++;
            }
        }
        if (NCCS/NCLR > 0.5) {
            PICK="CCS"
        } else {
            PICK="CLR"
        }
    }
    print PICK;
}
