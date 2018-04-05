TARGET=template
PORT=/dev/tty.usbserial-A906HNC1

all:
	zasm --z80 -buy -i $(TARGET).asm -o $(TARGET).bin
clean:
	rm -f *.bin *.lst
flash:
	caflash $(TARGET).bin $(PORT)
serial:
	screen $(PORT) 115200
