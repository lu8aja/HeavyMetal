 
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>

void usage() {
    printf("Error, must be of form 'setdiv port val'\n");
    printf("  port and val in decimal\n");
}

// Expects "setdiv port val" where port and val are in hex of form 0x00

int main(int argc, char **argv) {
    int port_addr;
    int divisor;

    if (argc == 3) {

	unsigned char old_lcr_val;
	short msl;
	short msh;
	short lcr;

	sscanf(argv[1],"%d",&port_addr);
	sscanf(argv[2],"%d",&divisor);

	printf("Setting divisor of uart at port 0x%x to %d\n",port_addr,divisor);

	msl = port_addr + 0;
	msh = port_addr + 1;
	lcr = port_addr + 3;

	if ((port_addr == 0) || (divisor == 0)) {
	    printf("Error: Invalid arguments\n");
	    usage();
	    return -1;
	}

	// Save control register settings
	old_lcr_val = _inp(lcr);

	// Set UART to recieve new divisor
	_outp(lcr,(old_lcr_val | 0x80));

	// Set new divisor a byte at a time
	_outp(msl,divisor & 0xff);
	_outp(msh,divisor >> 8);

	// Restore UART
	_outp(lcr,old_lcr_val);

    } else {
	usage();
        return -1;
    }

    return 0;
}

