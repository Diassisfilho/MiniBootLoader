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

// Simple delay function (Busy wait)
// Since we are in 32-bit mode without interrupts/PIT configured in this simple kernel,
// we burn CPU cycles. The count depends on CPU speed (QEMU/Real HW).
void delay_approx_5s() {
    // Volatile to prevent compiler optimization
    volatile unsigned long long count = 0;
    // Adjust this value if too fast/slow. ~100-500 million might be needed.
    while (count < 400000000) {
        count++;
    }
}

// Function to reboot the computer using the keyboard controller
void reboot() {
    // Send 0xFE to port 0x64 (CPU Reset)
    __asm__ __volatile__ ("outb %%al, %%dx" : : "a" (0xFE), "d" (0x64));
}

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

    // ==========================================================
    // MODIFICAÇÃO: Aguardar 5 segundos e Reiniciar
    // ==========================================================
    
    delay_approx_5s();
    
    reboot();

    // Halt
    while(1);
}