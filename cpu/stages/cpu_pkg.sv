

package cpu_pkg;

typedef struct packed {
    logic alu_a_mux_sel;
    logic alu_b_mux_sel;
    logic [2:0] alu_op;
    logic alu_aux;
    logic [2:0] branch_op;
} execut_control_vector_t;


endpackage : cpu_pkg