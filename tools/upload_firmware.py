#!/usr/bin/env python3
# File: /home/thomas/icebreaker/bootloader_upload.py

import argparse
import serial
import sys
import os
import time
from pathlib import Path

def wait_for_prompt(ser, expected_prompt):
    """Wait for the expected prompt from the bootloader"""
    received_data = b""
    
    print("Waiting for bootloader prompt...")
    
    while True:
        try:
            # Read one byte at a time to avoid missing the prompt
            byte = ser.read(1)
            if byte:
                received_data += byte
                # Print received characters for debugging
                try:
                    char = byte.decode('ascii')
                    print(char, end='', flush=True)
                except UnicodeDecodeError:
                    print(f"[0x{byte[0]:02x}]", end='', flush=True)
                
                # Check if we've received the expected prompt
                received_str = received_data.decode('ascii', errors='ignore')
                if expected_prompt in received_str:
                    print(f"\nFound expected prompt!")
                    return True
                    
                # Keep only the last part of the buffer to avoid memory issues
                if len(received_data) > len(expected_prompt.encode()) * 2:
                    received_data = received_data[-len(expected_prompt.encode()):]
                    
        except serial.SerialTimeoutException:
            continue
        except KeyboardInterrupt:
            print("\nInterrupted by user")
            return False

def send_size_and_file(ser, binary_file_path):
    """Send the file size and then the binary file content"""
    
    # Get file size
    file_size = os.path.getsize(binary_file_path)
    print(f"Binary file size: {file_size} bytes")
    
    # Send size as decimal ASCII string followed by newline
    size_str = f"{file_size}\n"
    print(f"Sending size: {size_str.strip()}")
    ser.write(size_str.encode('ascii'))
    ser.flush()
    
    # Wait a moment for the bootloader to process the size
    time.sleep(0.1)
    
    # Read and echo any response from the bootloader
    print("Bootloader response:")
    start_time = time.time()
    while time.time() - start_time < 2.0:  # Wait up to 2 seconds for response
        if ser.in_waiting > 0:
            response = ser.read(ser.in_waiting)
            try:
                print(response.decode('ascii'), end='', flush=True)
            except UnicodeDecodeError:
                for byte in response:
                    print(f"[0x{byte:02x}]", end='', flush=True)
        time.sleep(0.01)
    
    print(f"\nSending binary file: {binary_file_path}")
    
    # Send binary file content
    with open(binary_file_path, 'rb') as f:
        bytes_sent = 0
        while True:
            chunk = f.read(1024)  # Read in 1KB chunks
            if not chunk:
                break
            
            ser.write(chunk)
            bytes_sent += len(chunk)
            
            # Show progress
            progress = (bytes_sent / file_size) * 100
            print(f"\rProgress: {bytes_sent}/{file_size} bytes ({progress:.1f}%)", end='', flush=True)
            
            # Small delay to avoid overwhelming the bootloader
            time.sleep(0.01)
    
    ser.flush()
    print(f"\nFile transfer complete: {bytes_sent} bytes sent")

def echo_uart_output(ser):
    """Echo everything received from UART to stdout"""
    print("\n" + "="*50)
    print("Echoing UART output (Press Ctrl+C to exit):")
    print("="*50)
    
    try:
        while True:
            if ser.in_waiting > 0:
                data = ser.read(ser.in_waiting)
                try:
                    # Try to decode as ASCII
                    text = data.decode('ascii')
                    print(text, end='', flush=True)
                except UnicodeDecodeError:
                    # If not ASCII, print as hex
                    for byte in data:
                        if 32 <= byte <= 126:  # Printable ASCII
                            print(chr(byte), end='', flush=True)
                        else:
                            print(f"[0x{byte:02x}]", end='', flush=True)
            time.sleep(0.01)
            
    except KeyboardInterrupt:
        print("\nExiting...")

def main():
    parser = argparse.ArgumentParser(
        description="Upload binary file to EvovleRISCV bootloader via UART"
    )
    parser.add_argument(
        'binary_file',
        type=str,
        help='Path to the binary file to upload'
    )
    parser.add_argument(
        '--device',
        type=str,
        default='/dev/ttyUSB1',
        help='Serial device file (default: /dev/ttyUSB1)'
    )
    parser.add_argument(
        '--baud',
        type=int,
        default=57600,
        help='Baud rate (default: 57600)'
    )
    parser.add_argument(
        '--timeout',
        type=float,
        default=1.0,
        help='Serial timeout in seconds (default: 1.0)'
    )
    
    args = parser.parse_args()
    
    # Validate binary file exists
    if not os.path.isfile(args.binary_file):
        print(f"Error: Binary file '{args.binary_file}' not found")
        sys.exit(1)
    
    # Expected prompt from the bootloader (with typos as in the original)
    expected_prompt = "EvovleRISCV bootloader:\nPlese enter Size of image to laod:"
    
    try:
        # Open serial connection
        print(f"Opening serial connection to {args.device} at {args.baud} baud...")
        ser = serial.Serial(
            port=args.device,
            baudrate=args.baud,
            timeout=args.timeout,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE
        )
        
        print(f"Serial connection established")
        
        # Wait for bootloader prompt
        if not wait_for_prompt(ser, expected_prompt):
            print("Failed to receive expected prompt from bootloader")
            sys.exit(1)
        
        # Send file size and binary data
        send_size_and_file(ser, args.binary_file)
        
        # Echo UART output
        echo_uart_output(ser)
        
    except serial.SerialException as e:
        print(f"Serial error: {e}")
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"File error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)
    finally:
        try:
            ser.close()
            print("Serial connection closed")
        except:
            pass

if __name__ == "__main__":
    main()
