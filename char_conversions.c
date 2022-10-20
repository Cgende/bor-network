#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>

void hex2ascii(char[]);
void ascii2hex(char[]);
int hex2int(char);
void printString(char[], int);

int main(int argc, char *argv[]) {
        if (argc != 4) {
                fprintf(stderr, "Useage: ./hex string_to_convert current_format target_format\n");
                fprintf(stderr, "Supported formats are hex, bin and ascii\n");
                exit(1);
        }

        if ( !strcmp(argv[2],"hex") && !strcmp(argv[3],"ascii")) {
                hex2ascii(argv[1]);
        }
        if ( !strcmp(argv[2],"ascii") && !strcmp(argv[3],"hex")) {
                ascii2hex(argv[1]);
        }
}

int hex2int(char c) {
        int first = c / 16 - 3;
        if (first >= 3) {
                first = first - 2;
        }

        int second = c % 16;
        int result = first*10 + second;
        if(result > 9) result--;
        return result;
}

void hex2ascii(char hex_string[]) {
        int half_len, i, t_hex;
        int num_elements = strlen(hex_string);
        half_len = (num_elements / 2);
        char buff[half_len];
        for ( i=0; i < half_len; i++ ) {
                t_hex = (hex2int(hex_string[i *2]) * 16) + hex2int(hex_string[i * 2 + 1]);
                //printf("%c\n", t_hex);
                buff[i] = t_hex;
        }
        printString(buff, half_len);
        return;
}
void ascii2hex(char ascii[]) {
        int num_chars = strlen(ascii);
        printf("%d\n", num_chars);
        int i;
        char buff[num_chars * 2];


        int first, second;
        for (i=0; i < num_chars; i++) {
                first = (ascii[i] / 16) + 48;
                second = ascii[i] % 16;
                if (second < 10) {
                        second = second + 48;
                }
                else {
                        second = second + 87;
                }
                buff[i * 2] = first;
                buff[i * 2 + 1] = second;
        }
        printString(buff, num_chars * 2);
        return;
}

void printString(char c[], int length) {
        int i;
        for ( i=0; i < length; i++ ) {
                printf("%c", c[i]);
        }
        printf("\n");
        return;
}
