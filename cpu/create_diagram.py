import tkinter as tk
import io
from functools import partial
import re
import os
from graphviz import Digraph
from PIL import Image, ImageTk
import tempfile
import webbrowser

html_template = """
<!DOCTYPE html>
<html>
<head>
    <style>
        .edge:hover path {
            stroke: red;
            stroke-width: 2;
        }
        .edge:hover polygon {
            fill: red;
            stroke: red;
        }
    </style>
</head>
<body>
    {svg_content}
    <script>
        var edges = document.getElementsByClassName('edge');
        for (var i = 0; i < edges.length; i++) {
            edges[i].addEventListener('mouseover', function() {
                this.classList.add('highlight');
            });
            edges[i].addEventListener('mouseout', function() {
                this.classList.remove('highlight');
            });
        }
    </script>
</body>
</html>
"""

class VerilogModule:
    """
    Represents a Verilog module with its properties and submodules.

    Attributes:
        module_type (str): The type of the module.
        instance_name (str): The instance name of the module.
        parent (VerilogModule): The parent module, if any.
        ports (dict): A dictionary of ports and their properties.
        submodules (list): A list of submodules.
        parameters (dict): A dictionary of module parameters.
    """

    def __init__(self, module_type, instance_name=None, parent=None):
        """
        Initialize a VerilogModule instance.

        Args:
            module_type (str): The type of the module.
            instance_name (str, optional): The instance name of the module. Defaults to module_type.
            parent (VerilogModule, optional): The parent module. Defaults to None.
        """
        self.module_type = module_type
        self.instance_name = instance_name or module_type
        self.parent = parent
        self.ports = {}  # {port_name: {'direction': direction, 'wire': connected_wire}}
        self.submodules = []
        self.parameters = {}  # {param_name: param_value}

    def add_port(self, port_name, direction, connected_wire=None):
        """
        Add a port to the module.

        Args:
            port_name (str): The name of the port.
            direction (str): The direction of the port (input, output, or inout).
            connected_wire (str, optional): The wire connected to this port. Defaults to None.
        """
        self.ports[port_name] = {'direction': direction, 'wire': connected_wire}

    def add_submodule(self, submodule):
        """
        Add a submodule to this module.

        Args:
            submodule (VerilogModule): The submodule to add.
        """
        self.submodules.append(submodule)

    def add_parameter(self, param_name, param_value):
        """
        Add a parameter to the module.

        Args:
            param_name (str): The name of the parameter.
            param_value (str): The value of the parameter.
        """
        self.parameters[param_name] = param_value

def parse_module_definitions(verilog_files):
    """
    Parse Verilog files to extract module definitions.

    Args:
        verilog_files (list): A list of paths to Verilog files.

    Returns:
        dict: A dictionary of module definitions, where keys are module types and values are VerilogModule instances.
    """
    module_defs = {}
    for file_path in verilog_files:
        with open(file_path, 'r', encoding="utf-8") as file:
            content = file.read()

        # Extract module definitions, including those with parameters
        for match in re.finditer(r'module\s+(\w+)\s*(?:#\s*\((.*?)\))?\s*\((.*?)\);', content, re.DOTALL):
            module_type, params, ports = match.groups()
            module = VerilogModule(module_type)

            # Parse parameters if present
            if params:
                for param in re.findall(r'(\w+)\s*=\s*(\S+)', params):
                    param_name, param_value = param
                    module.add_parameter(param_name, param_value)

            # Parse ports with improved regex
            port_regex = r'(input|output|inout)\s*(?:reg|wire)?\s*(?:\[([^\]]+)\])?\s*(\w+)'
            for port in re.findall(port_regex, ports):
                direction, size, port_name = port
                if size:
                    port_info = f"{direction} [{size}] {port_name}"
                else:
                    port_info = f"{direction} {port_name}"
                module.add_port(port_name, port_info)

            module_defs[module_type] = module
            #print(f"Parsed module '{module_type}'")
            #print(module.ports)

    return module_defs

def parse_module_instantiations(top_file, module_defs):
    """
    Parse the top-level Verilog file to extract module instantiations.

    Args:
        top_file (str): Path to the top-level Verilog file.
        module_defs (dict): Dictionary of module definitions.

    Returns:
        VerilogModule: The top-level module with all its submodules and connections.

    Raises:
        ValueError: If no top-level module is found in the file.
    """
    with open(top_file, 'r', encoding='utf-8') as file:
        content = file.read()

    # Find the top-level module
    top_module_match = re.search(r'module\s+(\w+)', content)
    if not top_module_match:
        raise ValueError("No top-level module found in the file.")

    top_module_type = top_module_match.group(1)
    top_module = module_defs[top_module_type]

    def parse_instantiations(module, content):
        for inst in re.finditer(r'(\w+)\s*(?:#\s*\((.*?)\))?\s*(\w+)\s*\((.*?)\);', content, re.DOTALL):
            submodule_type, params, instance_name, connections = inst.groups()
            if submodule_type not in module_defs:
                print(f"Warning: Module type '{submodule_type}' not found in definitions.")
                continue

            # Create a new instance of the submodule based on its definition
            submodule = VerilogModule(submodule_type, instance_name, module)

            # Copy ports from the module definition
            for port_name, port_info in module_defs[submodule_type].ports.items():
                submodule.add_port(port_name, port_info['direction'])

            module.add_submodule(submodule)

            # Parse parameters if present
            if params:
                for param in re.findall(r'\.(\w+)\s*\(\s*(\S+)\s*\)', params):
                    param_name, param_value = param
                    submodule.add_parameter(param_name, param_value)

            # Parse connections
            for conn in re.findall(r'\.(\w+)\s*\((\w+)\)', connections):
                port_name, wire_name = conn
                if port_name in submodule.ports:
                    submodule.ports[port_name]['wire'] = wire_name

    parse_instantiations(top_module, content)
    return top_module

def create_cpu_diagram(top_module):
    """
    Create a Graphviz Digraph representing the CPU block diagram.

    Args:
        top_module (VerilogModule): The top-level module of the CPU.

    Returns:
        Digraph: A Graphviz Digraph object representing the CPU block diagram.
    """
    dot = Digraph(comment='CPU Block Diagram', engine='dot', format='svg')
    dot.attr(rankdir='TB')  # Change to top-to-bottom layout
    dot.attr('graph', ranksep='0.5', nodesep='0.3')  # Reduce spacing
    dot.attr('node', shape='box', style='filled', fontname='Arial', fontsize='10', margin='0.1,0.1')
    dot.attr('edge', fontname='Arial', fontsize='8')
    
    # Remove or comment out these lines:
    # dot.attr(splines='ortho')
    # dot.attr(concentrate='false')

    def add_module_to_graph(module, parent_name=None, depth=0):
        node_id = f"{module.instance_name}_{depth}"
        
        # Create port definitions
        port_defs = "\\n".join(f"{port}: {info['direction']}" for port, info in module.ports.items())
        
        # Create label with module name, ports, and parameters
        label = f"{module.instance_name}\\n{module.module_type}\\n{port_defs}"
        
        if module.parameters:
            param_defs = "\\n".join(f"{k}={v}" for k, v in module.parameters.items())
            label += f"\\n{param_defs}"
        
        # Create the node
        node_color = ['#E6F3FF', '#FFE6E6', '#E6FFE6', '#FFE6FF'][depth % 4]
        dot.node(node_id, label, fillcolor=node_color)

        if parent_name:
            dot.edge(parent_name, node_id)

        # Collect all connections within this module
        connections = {}
        for submodule in module.submodules:
            for port_name, port_info in submodule.ports.items():
                if port_info['wire']:
                    if port_info['wire'] not in connections:
                        connections[port_info['wire']] = []
                    connections[port_info['wire']].append((f"{submodule.instance_name}_{depth+1}", port_name, port_info['direction']))

        # Add connections from the current module to its parent
        for port_name, port_info in module.ports.items():
            if port_info['wire']:
                if port_info['wire'] not in connections:
                    connections[port_info['wire']] = []
                connections[port_info['wire']].append((node_id, port_name, port_info['direction']))

        # Create edges for connections
        for wire, connected_ports in connections.items():
            if len(connected_ports) == 2:
                source = next((p for p in connected_ports if 'output' in p[2]), None)
                target = next((p for p in connected_ports if 'input' in p[2]), None)
                if source and target:
                    dot.edge(source[0], target[0], label=f"{wire}\\n{source[1]} -> {target[1]}")
            elif len(connected_ports) > 2:
                # For multiple connections, create a junction point
                junction = f"{wire}_junction_{depth}"
                dot.node(junction, "", shape='point', width='0.1')
                for port in connected_ports:
                    if 'output' in port[2]:
                        dot.edge(port[0], junction, label=f"{wire}\\n{port[1]}")
                    else:
                        dot.edge(junction, port[0], label=f"{wire}\\n{port[1]}")

        for submodule in module.submodules:
            add_module_to_graph(submodule, node_id, depth + 1)

    add_module_to_graph(top_module)
    return dot

class ScalableImageWindow:
    """
    A Tkinter window for displaying and interacting with a scalable image.

    Attributes:
        master (tk.Tk): The root Tkinter window.
        original_image (PIL.Image): The original image to display.
        scale (float): The current scale factor of the image.
    """

    def __init__(self, master, image):
        """
        Initialize the ScalableImageWindow.

        Args:
            master (tk.Tk): The root Tkinter window.
            image (PIL.Image): The image to display.
        """
        self.master = master
        self.original_image = image
        self.master.title("CPU Block Diagram")

        # Create a frame to hold the canvas and scrollbars
        self.frame = tk.Frame(self.master)
        self.frame.pack(fill=tk.BOTH, expand=tk.YES)

        # Create horizontal and vertical scrollbars
        self.hbar = tk.Scrollbar(self.frame, orient=tk.HORIZONTAL)
        self.vbar = tk.Scrollbar(self.frame, orient=tk.VERTICAL)
        self.hbar.pack(side=tk.BOTTOM, fill=tk.X)
        self.vbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Create canvas and associate scrollbars
        self.canvas = tk.Canvas(self.frame, xscrollcommand=self.hbar.set, yscrollcommand=self.vbar.set)
        self.canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=tk.YES)

        self.hbar.config(command=self.canvas.xview)
        self.vbar.config(command=self.canvas.yview)

        self.tk_image = None
        self.image_on_canvas = None
        self.scale = 1.0
        self.resize_id = None

        # Bind events
        self.master.bind("&lt;Configure&gt;", self.schedule_resize)
        self.canvas.bind("&lt;ButtonPress-1&gt;", self.start_pan)
        self.canvas.bind("&lt;B1-Motion&gt;", self.pan)
        self.canvas.bind("&lt;Button-4&gt;", self.zoom)  # For Linux (scroll up)
        self.canvas.bind("&lt;Button-5&gt;", self.zoom)  # For Linux (scroll down)
        self.canvas.bind("&lt;Key&gt;", self.on_key)  # Bind key events

        self.draw_image()

        # Set focus to the canvas
        self.canvas.focus_set()

    def schedule_resize(self, event=None):
        """
        Schedule a resize event for the image.

        Args:
            event (tk.Event, optional): The event that triggered the resize. Defaults to None.
        """
        if self.resize_id:
            self.master.after_cancel(self.resize_id)
        self.resize_id = self.master.after(100, self.draw_image)

    def draw_image(self):
        """
        Draw the scaled image on the canvas.
        """
        self.resize_id = None
        width = int(self.master.winfo_width() * self.scale)
        height = int(self.master.winfo_height() * self.scale)

        if width <= 1 or height <= 1:  # Ignore invalid sizes
            return

        resized_image = self.original_image.copy()
        resized_image = resized_image.resize((width, height), Image.LANCZOS)

        self.tk_image = ImageTk.PhotoImage(resized_image)
        if self.image_on_canvas:
            self.canvas.delete(self.image_on_canvas)
        self.image_on_canvas = self.canvas.create_image(0, 0, image=self.tk_image, anchor=tk.NW)
        self.canvas.config(scrollregion=self.canvas.bbox(tk.ALL))

    def start_pan(self, event):
        """
        Start the panning operation.

        Args:
            event (tk.Event): The mouse event that started the pan.
        """
        self.canvas.scan_mark(event.x, event.y)

    def pan(self, event):
        """
        Continue the panning operation.

        Args:
            event (tk.Event): The mouse event for panning.
        """
        self.canvas.scan_dragto(event.x, event.y, gain=1)

    def zoom(self, event):
        """
        Handle zoom events for the canvas image.

        This method processes mouse scroll events to zoom in or out of the image
        when the Ctrl key is pressed, or to perform normal scrolling otherwise.

        Parameters:
        event (tkinter.Event): The event object containing information about the
                               scroll event, including:
                               - num: The scroll direction (4 for up, 5 for down)
                               - state: The state of modifier keys
                               - x, y: The mouse coordinates

        Returns:
        None

        Side effects:
        - Modifies self.scale to zoom in or out
        - Calls self.draw_image() to redraw the image with the new scale
        - Adjusts the canvas view to center on the mouse position
        - Scrolls the canvas vertically if Ctrl is not pressed
        """
        print(f"Zoom event: num={event.num}, state={event.state}")
        if event.state & 0x4:  # Check if Ctrl key is pressed
            x = self.canvas.canvasx(event.x)
            y = self.canvas.canvasy(event.y)
            
            if event.num == 5:  # Scroll down, zoom out
                self.scale /= 1.1
            elif event.num == 4:  # Scroll up, zoom in
                self.scale *= 1.1

            print(f"Zoom: scale={self.scale}")
            self.draw_image()

            # Adjust the view
            self.canvas.xview_moveto((x * self.scale - event.x) / self.tk_image.width())
            self.canvas.yview_moveto((y * self.scale - event.y) / self.tk_image.height())

        # If Ctrl is not pressed, allow normal scrolling
        else:
            if event.num == 4:
                self.canvas.yview_scroll(-1, "units")
            elif event.num == 5:
                self.canvas.yview_scroll(1, "units")

    def on_key(self, event):
        """
        Handle keyboard events for zooming in and out of the image.

        This method is triggered when a key is pressed. It checks if the Ctrl key
        is pressed along with either the plus or minus key to zoom in or out
        respectively.

        Parameters:
        event (tkinter.Event): The key event object containing information about
                               the key press, including which key was pressed and
                               the state of modifier keys.

        Returns:
        None

        Side effects:
        - Modifies self.scale to zoom in or out.
        - Calls self.draw_image() to redraw the image with the new scale.
        """
        if event.state & 0x4:  # Ctrl is pressed
            if event.keysym == 'plus':
                self.scale *= 1.1
            elif event.keysym == 'minus':
                self.scale /= 1.1
            self.draw_image()

def show_diagram(verilog_files, top_file):
    """
    Generate and display the CPU block diagram.

    Args:
        verilog_files (list): A list of paths to Verilog files.
        top_file (str): Path to the top-level Verilog file.
    """
    module_defs = parse_module_definitions(verilog_files)
    top_module = parse_module_instantiations(top_file, module_defs)
    dot = create_cpu_diagram(top_module)

    # Render the graph to SVG
    svg_data = dot.pipe(format='svg').decode('utf-8')

    # Save the SVG file
    svg_filename = "cpu_diagram.svg"
    with open(svg_filename, 'w', encoding='utf-8') as svg_file:
        svg_file.write(svg_data)
    print(f"SVG file saved as: {os.path.abspath(svg_filename)}")

    # Create a temporary HTML file
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.html') as f:
        # Split the HTML template into two parts
        html_parts = html_template.split('{svg_content}')

        # Write the first part of the HTML
        f.write(html_parts[0])

        # Write the SVG content directly, without formatting
        f.write(svg_data)

        # Write the second part of the HTML
        f.write(html_parts[1])

        temp_filename = f.name

    # Open the temporary HTML file in the default web browser
    webbrowser.open('file://' + temp_filename)

    print(f"HTML file created at: {temp_filename}")
    print("You can view the SVG directly using an SVG viewer, or open the HTML file in a web browser for interactivity.")

def find_verilog_files(directory):
    """
    Find all Verilog files in a given directory and its subdirectories.

    Args:
        directory (str): The path to the directory to search.

    Returns:
        list: A list of paths to Verilog files found.
    """
    verilog_files = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.v'):
                verilog_files.append(os.path.join(root, file))
    return verilog_files

if __name__ == "__main__":
    verilog_dir = "/home/thomas/icebreaker/hdl/cpu/"
    verilog_files = find_verilog_files(verilog_dir)
    print("Verilog files:", verilog_files)
    top_file = "/home/thomas/icebreaker/hdl/cpu/cpu.v"  # Specify your top-level file
    show_diagram(verilog_files, top_file)