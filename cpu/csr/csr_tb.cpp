
#include <stdlib.h>
#include "csr.h"
#include "../testbench_class.hpp"
#include <unordered_map>

class csr_state {
private:
    uint32_t initial_value;
    uint32_t value;
    uint32_t mask;
    uint32_t const_val;
public:
    csr_state();
    csr_state(uint32_t initial_value, uint32_t mask, uint32_t const_val);
    bool is_valid(uint32_t value);

    uint32_t get_value() { return this->value; }
    bool set(uint32_t mask, uint32_t value);
    bool clear(uint32_t mask, uint32_t value);
    bool write(uint32_t value_in, uint32_t value);
    void reset();
};

csr_state::csr_state() : value(0), mask(0), const_val(0) {}

csr_state::csr_state(uint32_t initial_value, uint32_t mask, uint32_t const_val) : initial_value(initial_value), value(initial_value), mask(mask), const_val(const_val) {}

void csr_state::reset(){
    this->value = this->initial_value;
}

bool csr_state::is_valid(uint32_t value) {
    return (this->value == value);
}

bool csr_state::set(uint32_t mask, uint32_t value) {
    uint32_t masked_value = this->mask & mask;
    this->value = this->value | masked_value;
    return this->is_valid(value);
}

bool csr_state::clear(uint32_t mask, uint32_t value) {
    uint32_t masked_value = this->mask & mask;
    this->value = this->value & ~masked_value;
    return this->is_valid(value);
}

bool csr_state::write(uint32_t value_in, uint32_t value) {
    uint32_t masked_value = this->mask & value_in;
    //printf("value_in: 0x%04x, masked_value: 0x%04x, mask: 0x%04x\n", value_in, masked_value, this->mask);
    //printf("value before: 0x%04x, ", this->value);
    this->value = (this->value & ~this->mask) | masked_value;
    //printf("value after: 0x%04x\n", this->value);
    return this->is_valid(value);
}

int main (int argc, char *argv[]) {
    TESTBENCH<csr> *tb = new TESTBENCH<csr>();
    tb->opentrace("csr.fst");
    csr* top = tb->get_dut();

    top->rst_n = 0;
    tb->tick();
    tb->tick();
    top->rst_n = 1;

    std::unordered_map<uint16_t, csr_state> *csr_map = new std::unordered_map<uint16_t, csr_state>();

    csr_map->insert({0xF11, csr_state()});
    csr_map->insert({0xF12, csr_state()});
    csr_map->insert({0xF13, csr_state()});
    csr_map->insert({0xF14, csr_state()});
    csr_map->insert({0xF15, csr_state()});

    csr_map->insert(
        {
            0x300, csr_state(0x1808, (1<<3) | (1<<7), 3 << 11)
        }
    );
    csr_map->insert({0x301, csr_state((1<<30) | (1<<8), 0x0, (1<<30) | (1<<8))});
    csr_map->insert({0x302, csr_state()});
    csr_map->insert({0x303, csr_state()});
    csr_map->insert({0x304, csr_state()});
    csr_map->insert({0x305, csr_state(0x0, 0xFFFFFFFC, 0x0)});
    csr_map->insert({0x306, csr_state()});
    csr_map->insert({0x310, csr_state()});
    csr_map->insert({0x312, csr_state()});

    csr_map->insert({0x340, csr_state(0x0, 0xFFFFFFFF, 0x0)});
    csr_map->insert({0x341, csr_state(0x0, 0xFFFFFFFC, 0x0)});
    csr_map->insert({0x342, csr_state(0x0, 0xFFFFFFFF, 0x0)});
    csr_map->insert({0x343, csr_state(0x0, 0xFFFFFFFF, 0x0)});
    csr_map->insert({0x344, csr_state()});
    csr_map->insert({0x34A, csr_state()});
    csr_map->insert({0x34B, csr_state()});

    csr_map->insert({0x30A, csr_state()});
    csr_map->insert({0x31A, csr_state()});
    csr_map->insert({0x747, csr_state()});
    csr_map->insert({0x757, csr_state()});

    csr_map->insert({0x3A0, csr_state()});
    csr_map->insert({0x3A1, csr_state()});
    csr_map->insert({0x3A2, csr_state()});
    csr_map->insert({0x3A3, csr_state()});
    csr_map->insert({0x3A4, csr_state()});
    csr_map->insert({0x3A5, csr_state()});
    csr_map->insert({0x3A6, csr_state()});
    csr_map->insert({0x3A7, csr_state()});
    csr_map->insert({0x3A8, csr_state()});
    csr_map->insert({0x3A9, csr_state()});
    csr_map->insert({0x3AA, csr_state()});
    csr_map->insert({0x3AB, csr_state()});
    csr_map->insert({0x3AC, csr_state()});
    csr_map->insert({0x3AD, csr_state()});
    csr_map->insert({0x3AE, csr_state()});
    csr_map->insert({0x3AF, csr_state()});

    csr_map->insert({0x3B0, csr_state()});
    csr_map->insert({0x3B1, csr_state()});
    csr_map->insert({0x3B2, csr_state()});
    csr_map->insert({0x3B3, csr_state()});
    csr_map->insert({0x3B4, csr_state()});
    csr_map->insert({0x3B5, csr_state()});
    csr_map->insert({0x3B6, csr_state()});
    csr_map->insert({0x3B7, csr_state()});
    csr_map->insert({0x3B8, csr_state()});
    csr_map->insert({0x3B9, csr_state()});
    csr_map->insert({0x3BA, csr_state()});
    csr_map->insert({0x3BB, csr_state()});
    csr_map->insert({0x3BC, csr_state()});
    csr_map->insert({0x3BD, csr_state()});
    csr_map->insert({0x3BE, csr_state()});
    csr_map->insert({0x3BF, csr_state()});
    csr_map->insert({0x3C0, csr_state()});
    csr_map->insert({0x3C1, csr_state()});
    csr_map->insert({0x3C2, csr_state()});
    csr_map->insert({0x3C3, csr_state()});
    csr_map->insert({0x3C4, csr_state()});
    csr_map->insert({0x3C5, csr_state()});
    csr_map->insert({0x3C6, csr_state()});
    csr_map->insert({0x3C7, csr_state()});
    csr_map->insert({0x3C8, csr_state()});
    csr_map->insert({0x3C9, csr_state()});
    csr_map->insert({0x3CA, csr_state()});
    csr_map->insert({0x3CB, csr_state()});
    csr_map->insert({0x3CC, csr_state()});
    csr_map->insert({0x3CD, csr_state()});
    csr_map->insert({0x3CE, csr_state()});
    csr_map->insert({0x3CF, csr_state()});
    csr_map->insert({0x3D0, csr_state()});
    csr_map->insert({0x3D1, csr_state()});
    csr_map->insert({0x3D2, csr_state()});
    csr_map->insert({0x3D3, csr_state()});
    csr_map->insert({0x3D4, csr_state()});
    csr_map->insert({0x3D5, csr_state()});
    csr_map->insert({0x3D6, csr_state()});
    csr_map->insert({0x3D7, csr_state()});
    csr_map->insert({0x3D8, csr_state()});
    csr_map->insert({0x3D9, csr_state()});
    csr_map->insert({0x3DA, csr_state()});
    csr_map->insert({0x3DB, csr_state()});
    csr_map->insert({0x3DC, csr_state()});
    csr_map->insert({0x3DD, csr_state()});
    csr_map->insert({0x3DE, csr_state()});
    csr_map->insert({0x3DF, csr_state()});
    csr_map->insert({0x3E0, csr_state()});
    csr_map->insert({0x3E1, csr_state()});
    csr_map->insert({0x3E2, csr_state()});
    csr_map->insert({0x3E3, csr_state()});
    csr_map->insert({0x3E4, csr_state()});
    csr_map->insert({0x3E5, csr_state()});
    csr_map->insert({0x3E6, csr_state()});
    csr_map->insert({0x3E7, csr_state()});
    csr_map->insert({0x3E8, csr_state()});
    csr_map->insert({0x3E9, csr_state()});
    csr_map->insert({0x3EA, csr_state()});
    csr_map->insert({0x3EB, csr_state()});
    csr_map->insert({0x3EC, csr_state()});
    csr_map->insert({0x3ED, csr_state()});
    csr_map->insert({0x3EE, csr_state()});
    csr_map->insert({0x3EF, csr_state()});
    csr_map->insert({0x30C, csr_state()});
    csr_map->insert({0x30D, csr_state()});
    csr_map->insert({0x30E, csr_state()});
    csr_map->insert({0x30F, csr_state()});
    csr_map->insert({0x31C, csr_state()});
    csr_map->insert({0x31D, csr_state()});
    csr_map->insert({0x31E, csr_state()});
    csr_map->insert({0x31F, csr_state()});

    /* Looping through invalid registers*/
    bool error = false;
    for (int i = 0; i < 4096 && !error; i++) {
        //bool is_valid = std::find(std::begin(valid_addresses), std::end(valid_addresses), i)!= std::end(valid_addresses);
        bool is_valid = csr_map->find(i) != csr_map->end();
        if (!is_valid) {
            for (int j = 0; j < 4 && !error; j++) {
                top->csr_rw_addr = i;
                top->csr_rw_data = 0x12345678;
                top->csr_control_signal = j;
                top->csr_trap_taken_in = 0;
                top->csr_mcause_in = 0x12345678;
                top->csr_pc_in = 0x12345678;
                top->csr_mtval_in = 0x12345678;

                tb->tick();

                if (j != 0) {
                    if (!top->csr_illegal_instr_out) {
                        printf("Error: CSR %x should have triggered a trap\n", i);
                        error = true;
                    }
                }
                else {
                    if (top->csr_illegal_instr_out) {
                        printf("Error: CSR %x should not have triggered a trap\n", i);
                        error = true;
                    }
                }

            }
        }
    }

    /* Testing valid registers*/

    std::unordered_map<uint16_t, csr_state>::iterator it = csr_map->begin();

    while (it!= csr_map->end()) {
        uint16_t address = it->first;
        csr_state &state = it->second;
        it++;

        top->csr_rw_addr = address;
        top->csr_rw_data = 0xFFFFFFFF;
        top->csr_control_signal = 1; //configure to write instruction, with data of 0xFFFFFFFF
        tb->tick();

        uint32_t read_data = top->csr_data_out; // The read data will always be off by one compared to the write data. THerefore, this contains the initial data
        // Check if initial value is correct
        if (!state.is_valid(read_data)) {
            printf("Error: CSR %x has invalid data after writing. Expected: 0x%x, got: 0x%x\n", address, state.get_value(), read_data);
        }
        top->csr_rw_data = 0x0;
        tb->tick();
        read_data = top->csr_data_out; // The read data will always be off by one compared to the write data.
        if (!state.write(0xFFFFFFFF, read_data)) {
            printf("Error: CSR %x could not write 0xFFFFFFFF to it. Expected: 0x%x, got: 0x%x\n", address, state.get_value(), read_data);
        }
        
        top->csr_control_signal = 2; //set register with data of 0 to just read the current value.
        tb->tick();
        read_data = top->csr_data_out;
        if (!state.write(0, read_data)) {
            printf("Error: CSR %x could not write 0 to it. Expected: 0x%x, got: 0x%x\n", address, state.get_value(), read_data);
        }

        uint32_t last_mask = 0;
        for (uint32_t i = 0; i < 33; i++) {
            uint32_t mask = (1 << i);
            top->csr_rw_data = mask;
            tb->tick();
            if (i > 0) {
                read_data = top->csr_data_out;
                if (!state.set(last_mask, read_data)) 
                {
                    printf("Error: CSR %x could not set bit %d to 1. Expected: 0x%x, got: 0x%x\n", address, i, state.get_value(), read_data);
                }
            }
            last_mask = mask;
        }

        top->csr_control_signal = 3; //clear bits in register
        last_mask = 0;
        for (uint32_t i = 0; i < 33; i++) {
            uint32_t mask = (1 << i);
            top->csr_rw_data = mask;
            tb->tick();
            if (i > 0) {
                read_data = top->csr_data_out;
                if (!state.clear(last_mask, read_data)) {
                    printf("Error: CSR %x could not clear bit %d to 0. Expected: 0x%x, got: 0x%x\n", address, i, state.get_value(), read_data);
                }
            }
            last_mask = mask;
        }

    }

    /* Testing interrupt/exception handling*/

    top->csr_control_signal = 2; // change to set command to read value
    top->csr_rw_data = 0; //set data to 0 so no change of any register happens.
    top->rst_n = 0; //trigger reset to ensure signals are in their default state
    tb->tick();
    tb->tick();
    top->rst_n = 1;

    tb->tick();

    // set mtvec register to get correct trap pc
    top->csr_rw_data = 0xDEADBEEF;
    top->csr_control_signal = 1;
    top->csr_rw_addr = 0x305;

    tb->tick();

    // This always needs to be set to mtvec (delayed by one clock cycle to write the data)
    if(top->csr_trap_pc_out != 0xDEADBEEC) {
        printf("CSR trap out not expected value of 0xDEADBEEC, actual value: %d\n", top->csr_trap_pc_out);
    }

    // set signal to indicate that a trap has to be taken. Now all writes to CSR
    // need to be rejected
    top->csr_trap_taken_in = 1;

    if (top->csr_trap_enabled != 1) {
        printf("ERROR: csr trap not enabled although it should be\n");
    }


    it = csr_map->begin();

    while (it!= csr_map->end()) {
        uint32_t address = it->first;
        csr_state &state = it->second;

        it++;

        top->csr_rw_addr = address;
        top->csr_rw_data = 0xFFFFFFFF;
        top->csr_control_signal = 1;

        tb->tick();

        if (top->csr_data_out != 0) {
            printf("ERROR: While trap is active, data is expected to be 0 but %x read\n", top->csr_data_out);
        }
    }
    // disable trap taken so data can be read out
    top->csr_trap_taken_in = 0;

    while (it!= csr_map->end()) {
        uint32_t address = it->first;
        csr_state &state = it->second;
        state.reset();
        it++;

        top->csr_rw_addr = address;
        top->csr_rw_data = 0x0;
        top->csr_control_signal = 2;

        tb->tick();

        if (!state.is_valid(top->csr_data_out)) {
            printf("ERROR: Register %x initial data expected but %x read\n", address, top->csr_data_out);
        }
    }


    top->csr_trap_taken_in = 1;


    it = csr_map->begin();

    while (it!= csr_map->end()) {
        uint32_t address = it->first;
        csr_state &state = it->second;

        it++;

        top->csr_rw_addr = address;
        top->csr_rw_data = 0x0;
        top->csr_control_signal = 1;

        tb->tick();

        if (top->csr_data_out != 0) {
            printf("ERROR: While trap is active, data is expected to be 0 but %x read\n", top->csr_data_out);
        }
    }
    // disable trap taken so data can be read out
    top->csr_trap_taken_in = 0;

    while (it!= csr_map->end()) {
        uint32_t address = it->first;
        csr_state &state = it->second;
        state.reset();
        it++;

        top->csr_rw_addr = address;
        top->csr_rw_data = 0x0;
        top->csr_control_signal = 2;

        tb->tick();

        if (!state.is_valid(top->csr_data_out)) {
            printf("ERROR: Register %x initial data expected but %x read\n", address, top->csr_data_out);
        }
    }
    // now we know that data provided while a trap is triggered is not written into the registers as expected

    top->csr_trap_taken_in = 1;
    top->csr_mcause_in = 0xFFFFFFFF;
    top->csr_pc_in = 0xFFFFFFFF;
    top->csr_mtval_in = 0xFFFFFFFF;
    tb->tick();
    top->csr_trap_taken_in = 0;
    // we change here mcause_in, pc_in and mtval_in to be able to see if these values are taken over although they should not be.
    top->csr_mcause_in = 0;
    top->csr_pc_in = 0;
    top->csr_mtval_in = 0;


    if ( top->csr_trap_enabled == 1) {
        printf("ERROR: Trap still enabled after trap was triggred\n");
    }

    top->csr_rw_addr = 0x342;
    top->csr_control_signal = 2;
    top->csr_rw_data = 0x0;

    tb->tick();
    if (top->csr_data_out != 0xFFFFFFFF) {
        printf("ERROR: mcause register does not contain exepcted value. Expected value: 0xFFFFFFFF, read value: %x", top->csr_data_out);
    }

    top->csr_rw_addr = 0x341;
    tb->tick();
    if (top->csr_data_out != 0xFFFFFFFF) {
        printf("ERROR: mepc register does not contain exepcted value. Expected value: 0xFFFFFFFF, read value: %x", top->csr_data_out);
    }

    top->csr_rw_addr = 0x343;
    tb->tick();
    if (top->csr_data_out != 0xFFFFFFFF) {
        printf("ERROR: mepc register does not contain exepcted value. Expected value: 0xFFFFFFFF, read value: %x", top->csr_data_out);
    }

    // testing the mret behavior
    top->rst_n = 0;
    tb->tick();
    tb->tick();
    top->rst_n = 1;

    if (top->csr_trap_enabled != 1) {
        printf("ERROR: csr trap not enabled although it should be\n");
    }

    top->csr_trap_taken_in = 1;
    tb->tick();

    if ( top->csr_trap_enabled == 1) {
        printf("ERROR: Trap still enabled after trap was triggred\n");
    }

    top->csr_trap_taken_in = 0;
    top->csr_mret_in = 1;
    tb->tick();
    
    if (top->csr_trap_enabled != 1) {
        printf("ERROR: csr trap not enabled although it should be\n");
    }


    tb->close();
}