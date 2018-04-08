#include <stdio.h>
#include <stdlib.h>
#include <ftdi.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>

int main(int argc, const char * argv[]) {
    
    if (argc < 2)
    {
        fprintf(stderr, "missing arguments\n");
        printf("usage: caflash binary_file_to_flash\n");
        exit(1);
    }
    
    char file_path[120];
    strcpy(file_path, argv[1]);
    
    FILE *file = fopen(file_path, "rb");
    if (!file) {
        fprintf(stderr, "opening file %s failed: %s\n", file_path, strerror(errno));
        exit(1);
    }
    fseek(file, 0, SEEK_END);
    uint16_t length = (uint16_t)(ftell(file));
    fseek(file, 0, SEEK_SET);
    uint8_t* data = malloc(length * sizeof(uint8_t) + 2);
    fread(data + 2, 1, length, file);
    fclose(file);
    
    *data = *(uint8_t*)(&length);
    *(data+1) = *((uint8_t*)(&length) + 1);
    
    printf("program: ");
    int i;
    for (i = 2; i < length + 2; i++)
    {
        printf("%02x ", data[i]);
    }
    printf("\n");
    
    printf("length: %d\n", length);
    
	
	int ret;
    struct ftdi_context *ftdi;
    ftdi = ftdi_new();
    ret = ftdi_usb_open(ftdi, 0x0403, 0x6001);
	if (ret < 0)
	{
	    fprintf(stderr, "opening serial port failed.\n");
		printf("hint: is the power on and the usb plugged in?\n");
	    ftdi_free(ftdi);
	    exit(1);
	}
	ftdi_usb_purge_buffers(ftdi);
	
    ftdi_set_baudrate(ftdi, 4800);
    ftdi_set_line_property(ftdi, 8, STOP_BIT_1, NONE);
	
    printf("uploading\n");
    ret = ftdi_write_data(ftdi, data, length + 2);
	printf("\n\n%d\n\n", ret);
	if (ret < 0)
	{
	    fprintf(stderr, "writing through serial port failed.\n");
	    printf("upload failed\n");
	    ftdi_usb_close(ftdi);
	    ftdi_free(ftdi);
	    exit(1);
	}
    
	
	printf("waiting for ack...\n");
	printf ("hint: are you in flash mode?\n");
    char ack[4] = {0x00, 0x00, 0x00, 0x00};
	usleep(10000);
    ret = ftdi_read_data(ftdi, (unsigned char*)ack, 3);
	if (ret == 0)
	{
	    fprintf(stderr, "no acknowledge received.\n");
	    printf("upload failed\n");
	    ftdi_usb_close(ftdi);
	    ftdi_free(ftdi);
	    exit(1);
	}
	
    if (strcmp(ack, "ACK") == 0)
    {
        printf("upload succesful\n");
    }
	
    ftdi_usb_close(ftdi);
    ftdi_free(ftdi);
	free(data);
    
    return 0;
}
