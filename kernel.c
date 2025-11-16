// A simple "print" function that writes to video memory
void print(char* str) {
    unsigned short* vga_buffer = (unsigned short*)0xB8000;
    int i = 0;
    while (str[i]) {
        vga_buffer[i] = (0x0F << 8) | str[i]; // White on Black
        i++;
    }
}

// Declare the external assembly function
extern int do_math(int a, int b);

// The main entry point for our C kernel
void main() {
    print("Hello from 32-bit C Kernel!");

    // Call the assembly function
    int result = do_math(10, 5);

    // We'd need an "int to string" function to print the result.
    // For now, we'll just prove it worked by halting.
    if (result == 15) {
        print("... ASM call success (10 + 5 = 15)!");
    } else {
        print("... ASM call failed!");
    }

    // Halt
    while(1);
}