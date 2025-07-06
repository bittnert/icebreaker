import tkinter as tk
from tkinter import filedialog
from create_diagram import parse_module_definitions, parse_module_instantiations, create_cpu_diagram
from graphviz import Digraph
from vcdvcd import VCDVCD
import os
from PIL import Image, ImageTk
import io

class VCDDiagram:
    def __init__(self, master):
        self.master = master
        self.master.title("VCD-based CPU Block Diagram")
        
        self.verilog_files = []
        self.top_file = ""
        self.vcd_file = ""
        self.vcd_data = None
        self.verilog_dir = ""  # Add this line to store the selected directory
        self.current_time = 0
        self.max_time = 0
        self.image = None
        self.setup_gui()

    def setup_gui(self):
        # Add buttons for file selection
        tk.Button(self.master, text="Select Verilog Directory", command=self.select_verilog_directory).pack()
        tk.Button(self.master, text="Select Top File", command=self.select_top_file).pack()
        tk.Button(self.master, text="Select VCD File", command=self.select_vcd_file).pack()
        tk.Button(self.master, text="Generate Diagram", command=self.generate_diagram).pack()

        # Add a scale for time selection
        self.time_scale = tk.Scale(self.master, from_=0, to=100, orient=tk.HORIZONTAL, label="Timestep", command=self.update_diagram)
        self.time_scale.pack(fill=tk.X, expand=True)

        # Change the canvas to a label for displaying the image
        self.image_label = tk.Label(self.master)
        self.image_label.pack(fill=tk.BOTH, expand=True)

    def select_verilog_directory(self):
        self.verilog_dir = filedialog.askdirectory(title="Select Verilog Directory")
        if self.verilog_dir:
            self.verilog_files = self.find_verilog_files(self.verilog_dir)
            print(f"Found {len(self.verilog_files)} Verilog files in the selected directory and its subdirectories.")

    def find_verilog_files(self, directory):
        verilog_files = []
        for root, dirs, files in os.walk(directory):
            for file in files:
                if file.endswith('.v'):
                    verilog_files.append(os.path.join(root, file))
        return verilog_files

    def select_top_file(self):
        self.top_file = filedialog.askopenfilename(filetypes=[("Verilog Files", "*.v")])

    def select_vcd_file(self):
        self.vcd_file = filedialog.askopenfilename(filetypes=[("VCD Files", "*.vcd")])
        if self.vcd_file:
            self.parse_vcd_file()

    def parse_vcd_file(self):
        self.vcd_data = VCDVCD(self.vcd_file)
        
        # Find the maximum time
        self.max_time = self.vcd_data.endtime
        self.time_scale.config(to=self.max_time)

    def generate_diagram(self):
        if not self.verilog_files or not self.top_file or not self.vcd_file:
            print("Please select all required files.")
            return

        self.module_defs = parse_module_definitions(self.verilog_files)
        self.top_module = parse_module_instantiations(self.top_file, self.module_defs)
        self.update_diagram()

    def update_diagram(self, time=None):
        if time is not None:
            self.current_time = int(float(time))
        
        dot = self.create_vcd_diagram()
        self.display_diagram_on_canvas(dot)

    def create_vcd_diagram(self):
        dot = create_cpu_diagram(self.top_module)
        
        # Modify the diagram to include signal values
        for signal_name in self.vcd_data.signals:
            value = self.get_signal_value(signal_name, self.current_time)
            # For now, let's add the value as a node label
            dot.node(signal_name, f"{signal_name}\n{value}")

        return dot

    def get_signal_value(self, signal_name, time):
        return self.vcd_data[signal_name][time]

    def display_diagram_on_canvas(self, dot):
        # Render the diagram to a PNG image
        png_data = dot.pipe(format='png')
        
        # Convert the PNG data to a PhotoImage
        image = Image.open(io.BytesIO(png_data))
        photo = ImageTk.PhotoImage(image)
        
        # Update the image in the label
        self.image_label.config(image=photo)
        self.image_label.image = photo  # Keep a reference to prevent garbage collection

if __name__ == "__main__":
    root = tk.Tk()
    app = VCDDiagram(root)
    root.mainloop()