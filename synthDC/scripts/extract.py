import re
import sys
import argparse
import os

def extract_module(module_name,file_path, output_path):
    with open(file_path, 'r') as f:
        verilog_content = f.read()
    
    # Define the pattern to match the module definition (starting with 'module alu' and ending with 'endmodule')
    # This handles possible spaces, tabs, and newlines.
    # pattern = r"module\s+alu\s*\(.*?\)[\s\S]*?endmodule"
    pattern = rf"module\s+{module_name}\s*\(([\s\S]*?)\)[\s\S]*?endmodule"


    # Search for the module using the pattern
    match = re.search(pattern, verilog_content)

    if match:
        # Extracted module content
        alu_module = match.group(0)
        
        # Write the extracted module to the output file
        with open(output_path, 'w') as output_file:
            output_file.write(alu_module)
        
        print(f"ALU module extracted successfully to {output_path}")
    else:
        print("ALU module not found in the given file.")

# Provide the path to your Verilog file and the output path for the extracted module
# file_path = '../runs/wallypipelinedcore_rv64gc_orig_freepdk15nm_1000_MHz_2025-04-22-12-27__dc75fb787/mapped/wallypipelinedcore.sv'  # Replace with your actual Verilog file path
# output_path = '../runs/wallypipelinedcore_rv64gc_orig_freepdk15nm_1000_MHz_2025-04-22-12-27__dc75fb787/mapped/alu.sv'  # Output file for extracted ALU module

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Extract a specific module from a Verilog file.")
    parser.add_argument("--module", type=str, help="Name of the module to extract.")
    parser.add_argument("--src", type=str, help="Path to the source Verilog file.")

    args = parser.parse_args()

    module_name = args.module
    file_path = args.src
    output_dir = os.path.dirname(file_path)

    # Setting output_path to be the directory + the module name as the filename with a .v extension
    output_path = os.path.join(output_dir, f"{module_name}.v")

    extract_module(module_name, file_path, output_path)
# Call the function to extract the module
# extract_alu_module(file_path, output_path)
