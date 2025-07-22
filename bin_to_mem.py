
import sys
import struct

def change_file_extension_with_string_methods(filename, new_extension):
    if '.' in filename:
        name, old_extension = filename.rsplit('.', 1)
        new_filename = name + '.' + new_extension
    else:
        new_filename = filename + '.' + new_extension
    return new_filename

if len(sys.argv) < 2:
    print("Missing argument. Please provide a file.")

file_name = sys.argv[1]

with open(file_name, 'rb') as file:
    data = file.read()

#if len(data) % 4 != 0:
#    print("ERROR: Expecting a multiple of 4 bytes.")
#    sys.exit(1)

output_filename = change_file_extension_with_string_methods(file_name, "mem")

with open(output_filename, 'w', encoding="ASCII") as output_file:
    for i in range(0, int(len(data)/4)*4, 4):
        value = struct.unpack("<I", data[i:i+4])[0]
        output_file.write(f"{value:08x}\n")
    
    remaining_bytes = len(data)%4
    if remaining_bytes > 0:
        filler = 4 - remaining_bytes

        for i in range(filler):
            output_file.write("00")

        for i in range(len(data) - 1, len(data) - remaining_bytes - 1, -1):
            value = data[i]
            output_file.write(f"{value:02x}")
