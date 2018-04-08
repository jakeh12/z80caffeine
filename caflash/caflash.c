#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <stdint.h>
#include <stdlib.h>

int main(int argc, const char * argv[]) {
    
    if (argc < 3)
    {
        fprintf(stderr, "missing arguments\n");
        printf("usage: caflash binary_file serial_port\n");
        exit(1);
    }
    
    char file_path[120];
    strcpy(file_path, argv[1]);

    char serial_path[120];
    strcpy(serial_path, argv[2]);
    
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
    for (i = 2; i < length; i++)
    {
        printf("%02x ", data[i]);
    }
    printf("\n");
    
    printf("length: %d\n", length);
    
    int ser;
    ser = open(serial_path, O_RDWR | O_NOCTTY | O_NDELAY);
    if (ser == -1) {
        fprintf(stderr, "opening serial port %s failed: %s\n", serial_path, strerror(errno));
		printf("hint: is the power on and the usb plugged in?\n");
	    free(data);
        exit(1);
    }
    
    fcntl(ser, F_SETFL, 0);
    
    struct termios options;
    tcgetattr(ser, &options);
    cfsetispeed(&options, B4800);
    cfsetospeed(&options, B4800);
    options.c_cflag |= (CLOCAL | CREAD);
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;
    options.c_cflag &= ~PARENB;
    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CRTSCTS;
    options.c_iflag &= ~(IXON | IXOFF | IXANY);
    options.c_oflag &= ~OPOST;
    options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
    options.c_cc[VTIME] = 10;
    options.c_cc[VMIN] = 0;
    tcsetattr(ser, TCSANOW, &options);
    
    printf("uploading\n");
    
    ssize_t n = write(ser, data, length + 2);
    usleep (100 * length);

    if (n < 0) {
        fprintf(stderr, "writing through serial port %s failed: %s\n", serial_path, strerror(errno));
        printf("upload failed\n");
        close(ser);
	    free(data);
        exit(1);
    }
    
    char ack[4] = {0x00, 0x00, 0x00, 0x00};
    n = read(ser, ack, 3);
    
    if (n == 0) {
        fprintf(stderr, "timeout ack from serial port %s: %s\n", serial_path, strerror(errno));
		printf ("hint: are you in flash mode?\n");
        printf("upload failed\n");
        close(ser);
	    free(data);
        exit(1);
    } else if (n < 0) {
        fprintf(stderr, "error reading serial port %s: %s\n", serial_path, strerror(errno));
        printf("upload failed\n");
        close(ser);
	    free(data);
        exit(1);

    }
    
    if (strcmp(ack, "ACK") == 0)
    {
        printf("upload succesful\n");
    }

    close(ser);
    free(data);
    return 0;
}