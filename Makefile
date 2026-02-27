TOOLCHAIN_PREFIX ?= riscv-none-elf-

# Give the user some easy overrides for local configuration quirks.
# If you change one of these and it breaks, then you get to keep both pieces.
SHELL = bash
PYTHON = python3
VERILATOR = verilator
ICARUS_SUFFIX =
IVERILOG = iverilog$(ICARUS_SUFFIX)
VVP = vvp$(ICARUS_SUFFIX)

# Build directories:
FIRMWARE_BUILD_DIR = firmware/build
TESTS_BUILD_DIR = tests/build
PROJ_DIR_BUILD_DIR = build
SYNTH_BUILD_DIR = $(PROJ_DIR_BUILD_DIR)/synth
SIM_BUILD_DIR = $(PROJ_DIR_BUILD_DIR)/sim
VERILATOR_BUILD_DIR = $(PROJ_DIR_BUILD_DIR)/testbench_verilator_dir

TEST_OBJS = $(patsubst tests/%.S,$(TESTS_BUILD_DIR)/%.o,$(wildcard tests/*.S))

FIRMWARE_OBJS = $(FIRMWARE_BUILD_DIR)/start.o $(FIRMWARE_BUILD_DIR)/irq.o $(FIRMWARE_BUILD_DIR)/print.o $(FIRMWARE_BUILD_DIR)/hello.o $(FIRMWARE_BUILD_DIR)/sieve.o $(FIRMWARE_BUILD_DIR)/multest.o $(FIRMWARE_BUILD_DIR)/stats.o
GCC_WARNS  = -Werror -Wall -Wextra -Wshadow -Wundef -Wpointer-arith -Wcast-qual -Wcast-align -Wwrite-strings
GCC_WARNS += -Wredundant-decls -Wstrict-prototypes -Wmissing-prototypes -pedantic # -Wconversion
COMPRESSED_ISA = C

# Add things like "export http_proxy=... https_proxy=..." here
GIT_ENV = true

check_task_0: test_synth
	@echo "Task 0 test succeeded!"

test: $(SIM_BUILD_DIR)/testbench.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $<

test_vcd: $(SIM_BUILD_DIR)/testbench.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $< +vcd +trace +noerror

#test_rvf: $(SIM_BUILD_DIR)/testbench_rvf.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
#$(VVP) -N $< +vcd +trace +noerror

test_wb: $(SIM_BUILD_DIR)/testbench_wb.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $<

test_wb_vcd: $(SIM_BUILD_DIR)/testbench_wb.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $< +vcd +trace +noerror

test_ez: $(SIM_BUILD_DIR)/testbench_ez.vvp
	$(VVP) -N $<

test_ez_vcd: $(SIM_BUILD_DIR)/testbench_ez.vvp
	$(VVP) -N $< +vcd

test_sp: $(SIM_BUILD_DIR)/testbench_sp.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $<

test_axi: $(SIM_BUILD_DIR)/testbench.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $< +axi_test

test_synth: $(SIM_BUILD_DIR)/testbench_synth.vvp $(FIRMWARE_BUILD_DIR)/firmware.hex
	$(VVP) -N $<

test_verilator: $(PROJ_DIR_BUILD_DIR)/testbench_verilator $(FIRMWARE_BUILD_DIR)/firmware.hex
	./$(PROJ_DIR_BUILD_DIR)/testbench_verilator

$(SIM_BUILD_DIR)/testbench.vvp: testbench.v picorv32.v | $(SIM_BUILD_DIR)
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

#$(SIM_BUILD_DIR)/testbench_rvf.vvp: testbench.v picorv32.v rvfimon.v
#$(IVERILOG) -o $@ -D RISCV_FORMAL $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
#chmod -x $@

$(SIM_BUILD_DIR)/testbench_wb.vvp: testbench_wb.v picorv32.v | $(SIM_BUILD_DIR)
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

$(SIM_BUILD_DIR)/testbench_ez.vvp: testbench_ez.v picorv32.v | $(SIM_BUILD_DIR)
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) $^
	chmod -x $@

$(SIM_BUILD_DIR)/testbench_sp.vvp: testbench.v picorv32.v | $(SIM_BUILD_DIR)
	$(IVERILOG) -o $@ $(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) -DSP_TEST $^
	chmod -x $@

$(SIM_BUILD_DIR)/testbench_synth.vvp: testbench.v $(SYNTH_BUILD_DIR)/synth.v | $(SIM_BUILD_DIR)
	$(IVERILOG) -o $@ -DSYNTH_TEST $^
	chmod -x $@

$(PROJ_DIR_BUILD_DIR)/testbench_verilator: testbench.v picorv32.v testbench.cc | $(VERILATOR_BUILD_DIR)
	# Run Verilator
	$(VERILATOR) --cc --exe -Wno-lint -trace --top-module picorv32_wrapper \
		$(abspath testbench.v) $(abspath picorv32.v) $(abspath testbench.cc) \
		$(subst C,-DCOMPRESSED_ISA,$(COMPRESSED_ISA)) \
		--Mdir $(VERILATOR_BUILD_DIR)

	# Build the executable
	$(MAKE) -C $(VERILATOR_BUILD_DIR) -f Vpicorv32_wrapper.mk

	# Copy resulting executable to top-level
	cp $(VERILATOR_BUILD_DIR)/Vpicorv32_wrapper $@

$(VERILATOR_BUILD_DIR):
	mkdir -p $(VERILATOR_BUILD_DIR)

check: check-yices

check-%: check.smt2
	yosys-smtbmc -s $(subst check-,,$@) -t 30 --dump-vcd check.vcd check.smt2
	yosys-smtbmc -s $(subst check-,,$@) -t 25 --dump-vcd check.vcd -i check.smt2

check.smt2: picorv32.v
	yosys -v2 -p 'read_verilog -formal picorv32.v' \
	          -p 'prep -top picorv32 -nordff' \
		  -p 'assertpmux -noinit; opt -fast; dffunmap' \
		  -p 'write_smt2 -wires check.smt2'

synth: $(SYNTH_BUILD_DIR)/synth.v

$(SYNTH_BUILD_DIR)/synth.v: picorv32.v scripts/yosys/synth_sim.ys | $(SYNTH_BUILD_DIR)
	yosys -qv3 -l $(SYNTH_BUILD_DIR)/synth.log scripts/yosys/synth_sim.ys

$(SIM_BUILD_DIR): $(PROJ_DIR_BUILD_DIR)
	mkdir -p $(SIM_BUILD_DIR)

$(SYNTH_BUILD_DIR): $(PROJ_DIR_BUILD_DIR)
	mkdir -p $(SYNTH_BUILD_DIR)

$(PROJ_DIR_BUILD_DIR):
	mkdir -p $(PROJ_DIR_BUILD_DIR)

$(FIRMWARE_BUILD_DIR)/firmware.hex: $(FIRMWARE_BUILD_DIR)/firmware.bin firmware/makehex.py
	$(PYTHON) firmware/makehex.py $< 32768 > $@

$(FIRMWARE_BUILD_DIR)/firmware.bin: $(FIRMWARE_BUILD_DIR)/firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@
	chmod -x $@

$(FIRMWARE_BUILD_DIR)/firmware.elf: $(FIRMWARE_OBJS) $(TEST_OBJS) firmware/sections.lds
	$(TOOLCHAIN_PREFIX)gcc -Os -mabi=ilp32 -march=rv32im -ffreestanding -nostdlib -o $@ \
		-Wl,--build-id=none,-Bstatic,-T,firmware/sections.lds,-Map,$(FIRMWARE_BUILD_DIR)/firmware.map,--strip-debug \
		$(FIRMWARE_OBJS) $(TEST_OBJS) -lgcc
	chmod -x $@

$(FIRMWARE_BUILD_DIR)/start.o: firmware/start.S | $(FIRMWARE_BUILD_DIR)
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im -o $@ $<

$(FIRMWARE_BUILD_DIR)/%.o: firmware/%.c | $(FIRMWARE_BUILD_DIR)
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im -Os --std=c99 $(GCC_WARNS) -ffreestanding -nostdlib -o $@ $<

$(FIRMWARE_BUILD_DIR):
	mkdir -p $(FIRMWARE_BUILD_DIR)

$(TESTS_BUILD_DIR)/%.o: tests/%.S tests/riscv_test.h tests/test_macros.h | $(TESTS_BUILD_DIR)
	$(TOOLCHAIN_PREFIX)gcc -c -mabi=ilp32 -march=rv32im -o $@ -DTEST_FUNC_NAME=$(notdir $(basename $<)) \
		-DTEST_FUNC_TXT='"$(notdir $(basename $<))"' -DTEST_FUNC_RET=$(notdir $(basename $<))_ret $<

$(TESTS_BUILD_DIR):
	mkdir -p $(TESTS_BUILD_DIR)

toc:
	gawk '/^-+$$/ { y=tolower(x); gsub("[^a-z0-9]+", "-", y); gsub("-$$", "", y); printf("- [%s](#%s)\n", x, y); } { x=$$0; }' README.md

clean:
	rm -vrf $(FIRMWARE_OBJS) $(TEST_OBJS) check.smt2 check.vcd synth.v synth.log \
		$(FIRMWARE_BUILD_DIR) \
		$(PROJ_DIR_BUILD_DIR) \
		$(SYNTH_BUILD_DIR) \
		$(VERILATOR_BUILD_DIR) \
		$(TESTS_BUILD_DIR)

.PHONY: test test_vcd test_sp test_axi test_wb test_wb_vcd test_ez test_ez_vcd test_synth download-tools build-tools toc clean
