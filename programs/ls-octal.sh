#!/bin/bash

ls -l --color=auto "$@" | awk '{
    octal_perm = 0;
    for(i=0; i<=8; i++)
    {
        octal_perm += ((substr($1,i+2,1)~/[rwx]/)*2^(8-i));
    }
    if(octal_perm > 0)
    {
        printf("%0o ", octal_perm);
    }
    print
}'

