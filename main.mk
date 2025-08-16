#sim: obj_dir/$(PROJ).a $(V_SRC) $(SIM_SRC)
#	$(CXX) $(addprefix -I,$(INC_DIR)) $(SIM_SRC) obj_dir/$(PROJ)__ALL.a  -o output
#	./output
#	gtkwave test.vcd

PACKAGE:="sg48"

%.sim: $(SIM_SRC) %_tb.cpp  %.a $(TOP).a 
	$(CXX) $(addprefix -I, $(INC_DIR)) -g -DTRACE_EXECUTION  $^ -o $*.sim -lz
#	./$*.sim
#	gtkwave $*.sim.vcd
	

%.a: $(V_SRC) $(SIM_V_SRC) #$(MEM_FILE)
	verilator -Wall --trace-fst --vpi --public-flat-rw --prefix $* --build "-DVL_DEBUG" -DTRACE_EXECUTION --top-module $(TOP) --cc $(V_SRC) $(SIM_V_SRC) --public
	cp obj_dir/$*__ALL.a ./$*.a

.PRECIOUS: cpu.rpt cpu.asc cpu.json


%.mem: %.binary
	python ../bin_to_mem.py $^

%.binary: %.out
	riscv64-linux-gnu-ld -T custom.ld -o $(basename $(@)).elf $^
	riscv64-linux-gnu-objcopy -O binary $(basename $(@)).elf $@

%.out: %.S
	riscv64-linux-gnu-as $^ -o $@

%.json: $(V_SRC) #$(MEM_FILE)
		yosys -ql $*.log -p 'synth_ice40 -abc9 -dsp -spram -top $* -json $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) $(if $(PACKAGE), --package $(PACKAGE)) $(if $(FREQ),--freq $(FREQ)) --json $(filter-out $<,$^) --pcf $< --asc $@

%.bin: %.asc %.rpt
	icepack $< $@

%.rpt: %.asc
	icetime $(if $(FREQ),-c $(FREQ)) -d $(DEVICE) -mtr $@ $<

%.prog: %.bin
	@echo "Escuting prog as root!!!"
	sudo iceprog $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

clean:
	rm -rf obj_dir *.vcd *.sim *.blif *.asc *.rpt *.bin *.json *.log $(ADD_CLEAN) *.sim *.a

.PHONY: all 
