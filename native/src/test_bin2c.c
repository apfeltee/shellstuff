
#include <stdio.h>
#include "dump.h"

int main()
{
    fwrite(data_field_data, sizeof(unsigned char), data_field_size, stdout);
    fflush(stdout);
    return 0;
}

