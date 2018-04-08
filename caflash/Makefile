all:
	gcc -o caflash caflash.c -I/usr/local/Cellar/libftdi/1.4/include/libftdi1 -L/usr/local/Cellar/libftdi/1.4/lib -lftdi1

install:
	cp caflash /usr/local/bin
clean:
	rm -f caflash
	