import os
import subprocess
import glob
import time
import sys
from datetime import timedelta

work_base_dir = "riscof_work/rv32i_m/I/src/"

def run_tests():
    # Check if the directory exists
    if not os.path.isdir(work_base_dir):
        print(f"Error: Directory '{work_base_dir}' does not exist")
        return
    
    # Get all subdirectories
    subdirs = [d for d in os.listdir(work_base_dir) if os.path.isdir(os.path.join(work_base_dir, d))]
    
    if not subdirs:
        print(f"No subdirectories found in '{work_base_dir}'")
        return
    
    print(f"Found {len(subdirs)} test directories")
    
    # Process each subdirectory
    for subdir in subdirs:
        cmd = f"./cpu.sim {work_base_dir}{subdir}/dut/my.elf.hex {work_base_dir}{subdir}/dut/my.elf.bin {work_base_dir}{subdir}/dut/my.elf.map"
        
        print(f"Running test for {subdir}...")
        start_time = time.time()
        
        # Use Popen with line buffering to get real-time output
        process = subprocess.Popen(
            cmd, 
            shell=True, 
            stdout=subprocess.PIPE, 
            stderr=subprocess.PIPE, 
            text=True, 
            bufsize=1,  # Line buffered
            universal_newlines=True
        )
        
        # Track elapsed time
        elapsed = 0
        
        # Process output in real-time
        while process.poll() is None:
            # Read any available output
            for line in process.stdout:
                print(f"[{subdir}] {line.strip()}")
                
            # Update elapsed time
            current_elapsed = time.time() - start_time
            if int(current_elapsed) > int(elapsed):
                elapsed = current_elapsed
                elapsed_str = str(timedelta(seconds=int(elapsed)))
                print(f"Test running for: {elapsed_str}", end="\r")
                sys.stdout.flush()
            
            # Small sleep to prevent CPU hogging
            time.sleep(0.1)
        
        # Get any remaining output
        for line in process.stdout:
            print(f"[{subdir}] {line.strip()}")
            
        # Get any error output
        stderr_output = process.stderr.read()
        if stderr_output:
            print(f"Error output from {subdir}:")
            print(stderr_output)
        
        # Print final status
        elapsed_total = time.time() - start_time
        elapsed_total_str = str(timedelta(seconds=int(elapsed_total)))
        
        if process.returncode == 0:
            print(f"\nTest for {subdir} completed successfully in {elapsed_total_str}")
        else:
            print(f"\nError running test for {subdir} after {elapsed_total_str}")

if __name__ == "__main__":
    run_tests()