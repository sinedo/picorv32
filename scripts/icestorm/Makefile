TOOLCHAIN_PREFIX = riscv-none-elf-
ICE40_SIM_CELLS=$(shell yosys-config --datdir/ice40/cells_sim.v)

BUILD_DIR := build
FIRMWARE_BUILD_DIR = $(BUILD_DIR)/firmware
SIM_BUILD_DIR = $(BUILD_DIR)/sim
SYNTH_BUILD_DIR = $(BUILD_DIR)/synth
PNR_BUILD_DIR = $(BUILD_DIR)/pnr
BITSTREAM_BUILD_DIR = $(BUILD_DIR)/bitstream

# set to 4 for simulation
FIRMWARE_COUNTER_BITS=18

all: $(BITSTREAM_BUILD_DIR)/example.bin

## -------------------
## firmware generation

$(FIRMWARE_BUILD_DIR)/firmware.elf: firmware.S firmware.c firmware.lds | $(FIRMWARE_BUILD_DIR)
	$(TOOLCHAIN_PREFIX)gcc \
		-DSHIFT_COUNTER_BITS=$(FIRMWARE_COUNTER_BITS) \
		-march=rv32imc -Os -ffreestanding -nostdlib \
		-o $@ firmware.S firmware.c \
		--std=gnu99 -Wl,-Bstatic,-T,firmware.lds,-Map,$(FIRMWARE_BUILD_DIR)/firmware.map,--strip-debug
	chmod -x $@

$(FIRMWARE_BUILD_DIR)/firmware.bin: $(FIRMWARE_BUILD_DIR)/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

$(FIRMWARE_BUILD_DIR)/firmware.hex: $(FIRMWARE_BUILD_DIR)/firmware.bin
	python3 ../../firmware/makehex.py $< 128 > $@

## ------------------------------
## main flow: synth/p&r/bitstream

$(SYNTH_BUILD_DIR)/synth.json: example.v ../../picorv32.v $(FIRMWARE_BUILD_DIR)/firmware.hex | $(SYNTH_BUILD_DIR)
	yosys -v3 -l $(SYNTH_BUILD_DIR)/synth.log -p 'synth_ice40 -top top -json $@; write_verilog -attr2comment $(SYNTH_BUILD_DIR)/synth.v' $(filter %.v, $^)

$(PNR_BUILD_DIR)/example.asc: $(SYNTH_BUILD_DIR)/synth.json example.pcf | $(PNR_BUILD_DIR)
	nextpnr-ice40 --up5k --package sg48 --json $< --pcf example.pcf --asc $@

$(BITSTREAM_BUILD_DIR)/example.bin: $(PNR_BUILD_DIR)/example.asc | $(BITSTREAM_BUILD_DIR)
	icepack $< $@

## -----------------
## icarus simulation

$(SIM_BUILD_DIR)/example_tb.vvp: example.v example_tb.v ../../picorv32.v $(FIRMWARE_BUILD_DIR)/firmware.hex | $(SIM_BUILD_DIR)
	iverilog -o $@ -s testbench $(filter %.v, $^)
	chmod -x $@

example_sim: $(SIM_BUILD_DIR)/example_tb.vvp
	vvp -N $<

example_sim_vcd: $(SIM_BUILD_DIR)/example_tb.vvp
	vvp -N $< +vcd

## ---------------------
## post-synth simulation

$(SIM_BUILD_DIR)/synth_tb.vvp: example_tb.v $(SYNTH_BUILD_DIR)/synth.json | $(SIM_BUILD_DIR)
	iverilog -o $@ -s testbench $(SYNTH_BUILD_DIR)/synth.v example_tb.v $(ICE40_SIM_CELLS) -D NO_ICE40_DEFAULT_ASSIGNMENTS
	chmod -x $@

synth_sim: $(SIM_BUILD_DIR)/synth_tb.vvp
	vvp -N $<

synth_sim_vcd: $(SIM_BUILD_DIR)/synth_tb.vvp
	vvp -N $< +vcd

## ---------------------
## post-route simulation

$(PNR_BUILD_DIR)/route.v: $(PNR_BUILD_DIR)/example.asc example.pcf
	icebox_vlog -n top -sp example.pcf $< > $@

# Note that this target is not functional, as icebox_vlog produces a verilog file with duplicate names
# This results in an error in iverilog
# If one wants to simulate the routed design feel free to change this manually or by a script :)
$(SIM_BUILD_DIR)/route_tb.vvp: $(PNR_BUILD_DIR)/route.v example_tb.v | $(SIM_BUILD_DIR)
	iverilog -o $@ -s testbench $^ $(ICE40_SIM_CELLS) -D NO_ICE40_DEFAULT_ASSIGNMENTS
	chmod -x $@

route_sim: $(SIM_BUILD_DIR)/route_tb.vvp
	vvp -N $<

route_sim_vcd: $(SIM_BUILD_DIR)/route_tb.vvp
	vvp -N $< +vcd

## ---------------------
## miscellaneous targets

prog_sram: $(BITSTREAM_BUILD_DIR)/example.bin
	iceprog -S $<

timing: $(PNR_BUILD_DIR)/example.asc example.pcf
	icetime -c 12 -tmd up5k -P sg48 -p example.pcf -t $<

view: $(SIM_BUILD_DIR)/example.vcd
	gtkwave $< example.gtkw

## ------
## el fin

# --- Build dirs ---

$(FIRMWARE_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $(FIRMWARE_BUILD_DIR)

$(SIM_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $(SIM_BUILD_DIR)

$(SYNTH_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $(SYNTH_BUILD_DIR)/

$(PNR_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $(PNR_BUILD_DIR)

$(BITSTREAM_BUILD_DIR): $(BUILD_DIR)
	mkdir -p $(BITSTREAM_BUILD_DIR)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -vrf $(BUILD_DIR)

.PHONY: all prog_sram view clean
.PHONY: example_sim synth_sim route_sim timing
.PHONY: example_sim_vcd synth_sim_vcd route_sim_vcd
