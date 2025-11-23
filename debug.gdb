# --- GDB Script to connect to a remote target and set breakpoints ---

# Connect to the remote target running on localhost at port 1234
target remote localhost:1234

# Set breakpoints at the specified addresses
# Note: Ensure these addresses are valid within the loaded binary/context
break *0x7C00
break *0x70B9
break *0x70BB

# You can add further commands here, e.g., 'continue' to start running until the first breakpoint is hit:
#continue