
all: $(PROJ).bin

#sim: obj_dir/$(PROJ).a $(V_SRC) $(SIM_SRC)
#	$(CXX) $(addprefix -I,$(INC_DIR)) $(SIM_SRC) obj_dir/$(PROJ)__ALL.a  -o output
#	./output
#	gtkwave test.vcd

%.sim: $(SIM_SRC) %_tb.cpp  %.a
	$(CXX) $(addprefix -I, $(INC_DIR)) -DTRACE_EXECUTION  $^ -o $*.sim
	./$*.sim
	gtkwave $*.sim.vcd
	

%.a: $(V_SRC)
	verilator -Wall --trace --prefix $* --build -DTRACE_EXECUTION --top-module $* --cc $(V_SRC)
	cp obj_dir/$*__ALL.a ./$*.a

%.json: $(V_SRC)
	yosys -ql $*.log -p 'synth_ice40 -abc2 -top $* -json $@' $^

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) $(if $(PACKAGE), --package $(PACKAGE)) $(if $(FREQ),--freq $(FREQ)) --json $(filter-out $<,$^) --pcf $< --asc $@

%.bin: %.asc
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
	rm -rf obj_dir *.vcd *.sim $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json $(PROJ).log $(ADD_CLEAN)

.PHONY: all 
