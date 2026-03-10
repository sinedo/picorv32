# Select your RISC-V compiler here (riscv32i/riscv32im/riscv32ic/riscv32imc)
RISCV_ISA = imc

# Build directories:
BUILD_DIR := build
FIRMWARE_BUILD_DIR = $(BUILD_DIR)/firmware
SIM_BUILD_DIR = $(BUILD_DIR)/sim
SYNTH_BUILD_DIR = $(BUILD_DIR)/synth
PNR_BUILD_DIR = $(BUILD_DIR)/pnr
BITSTREAM_BUILD_DIR = $(BUILD_DIR)/bitstream

CROSS ?= riscv-none-elf-
CFLAGS= -O3 -march=rv32$(RISCV_ISA)

DHRY_SRCS = dhrystone/dhry.h dhrystone/stdlib.c dhrystone/dhry_2.c dhrystone/dhry_1.c
BRAM_SIZE = 3072

# ---- Firmware analysis ----

size: $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf
	$(CROSS)size $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf

dis: $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf
	$(CROSS)objdump -d $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf

disdump: $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf
	$(CROSS)objdump -D $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf > $(FIRMWARE_BUILD_DIR)/icebreaker_fw.s

# ---- iCE40 IceBreaker Board ----

sim: $(SIM_BUILD_DIR)/icebreaker_tb.vpp $(FIRMWARE_BUILD_DIR)/icebreaker_fw.hex $(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.hex
	vvp -N $< +firmware=$(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.hex

synsim: $(SIM_BUILD_DIR)/icebreaker_syn_tb.vvp $(FIRMWARE_BUILD_DIR)/icebreaker_fw.hex
	vvp -N $< +firmware=$(FIRMWARE_BUILD_DIR)/icebreaker_fw.hex

pnr: $(PNR_BUILD_DIR)/icebreaker.asc

# Programming targets using the explicit firmware builds
prog_flash: $(BITSTREAM_BUILD_DIR)/icebreaker_flash.bin $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.bin
	iceprog $(BITSTREAM_BUILD_DIR)/icebreaker_flash.bin
	iceprog -o 1M $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.bin

prog_bram: $(BITSTREAM_BUILD_DIR)/icebreaker_bram.bin $(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.hex $(FIRMWARE_BUILD_DIR)/icebreaker_fw_random.hex
	iceprog $(BITSTREAM_BUILD_DIR)/icebreaker_bram.bin

prog_fw: $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.bin
	iceprog -o 1M $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.bin

# ---- Testbench for SPI Flash Model ----
spiflash_tb: $(SIM_BUILD_DIR)/spiflash_tb.vvp $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.hex
	vvp -N $< +firmware=$(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.hex

# Build firmware for flash
$(FIRMWARE_BUILD_DIR)/icebreaker_flash_sections.lds: sections.lds | $(FIRMWARE_BUILD_DIR)
	$(CROSS)cpp -P -DICEBREAKER -DEXECUTE_FROM_FLASH -o $@ $<

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.elf: $(FIRMWARE_BUILD_DIR)/icebreaker_flash_sections.lds start.s firmware.c $(DHRY_SRCS) | $(FIRMWARE_BUILD_DIR)
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -DTIME -DRISCV -DUSE_MYSTDLIB -ffreestanding -nostdlib -mabi=ilp32 -march=rv32$(RISCV_ISA) \
	-Wl,-Bstatic,-T,$(FIRMWARE_BUILD_DIR)/icebreaker_flash_sections.lds,-Map,$(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.map,--strip-debug \
	-o $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.elf start.s firmware.c $(DHRY_SRCS) \
	-Wno-implicit-int -Wno-implicit-function-declaration -lgcc

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.hex: $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.elf
	$(CROSS)objcopy -O verilog $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.elf $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.hex

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.bin: $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.elf
	$(CROSS)objcopy -O binary $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.elf $(FIRMWARE_BUILD_DIR)/icebreaker_fw_flash.bin

# Build firmware for bram
$(FIRMWARE_BUILD_DIR)/icebreaker_bram_sections.lds: sections.lds | $(FIRMWARE_BUILD_DIR)
	$(CROSS)cpp -P -DICEBREAKER -o $@ $<

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.elf: $(FIRMWARE_BUILD_DIR)/icebreaker_bram_sections.lds start.s firmware.c $(DHRY_SRCS) | $(FIRMWARE_BUILD_DIR)
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -DTIME -DRISCV -DUSE_MYSTDLIB -ffreestanding -nostdlib -mabi=ilp32 -march=rv32$(RISCV_ISA) \
	-Wl,-Bstatic,-T,$(FIRMWARE_BUILD_DIR)/icebreaker_bram_sections.lds,-Map,$(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.map,--strip-debug \
	-o $(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.elf start.s firmware.c $(DHRY_SRCS) \
	-Wno-implicit-int -Wno-implicit-function-declaration -lgcc

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.hex: $(FIRMWARE_BUILD_DIR)/icebreaker_fw.bin
	python3 ../firmware/makehex.py $< $(BRAM_SIZE) > $@

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.bin: $(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.elf
	$(CROSS)objcopy -O binary $(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.elf $(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.bin

$(FIRMWARE_BUILD_DIR)/icebreaker_fw_random.hex:
	icebram -g 32 $(BRAM_SIZE) > $@

# Firmware for simulation:

$(FIRMWARE_BUILD_DIR)/icebreaker_fw.hex: $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf
	$(CROSS)objcopy -O verilog $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf $(FIRMWARE_BUILD_DIR)/icebreaker_fw.hex

$(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf: $(FIRMWARE_BUILD_DIR)/icebreaker_sections.lds start.s firmware.c $(DHRY_SRCS) | $(FIRMWARE_BUILD_DIR)
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -DTIME -DRISCV -DUSE_MYSTDLIB -ffreestanding -nostdlib -mabi=ilp32 -march=rv32$(RISCV_ISA) -Wl,-Bstatic,-T,$(FIRMWARE_BUILD_DIR)/icebreaker_sections.lds,-Map,$(FIRMWARE_BUILD_DIR)/icebreaker_fw.map,--strip-debug -o $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf start.s firmware.c $(DHRY_SRCS) -Wno-implicit-int -Wno-implicit-function-declaration -lgcc

$(FIRMWARE_BUILD_DIR)/icebreaker_sections.lds: sections.lds | $(FIRMWARE_BUILD_DIR)
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

$(FIRMWARE_BUILD_DIR)/icebreaker_fw.bin: $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf
	$(CROSS)objcopy -O binary $(FIRMWARE_BUILD_DIR)/icebreaker_fw.elf $(FIRMWARE_BUILD_DIR)/icebreaker_fw.bin

# ---- Synthesis ----
$(SYNTH_BUILD_DIR)/icebreaker.json: icebreaker.v spimemio.v simpleuart.v picosoc.v ice40up5k_spram.v ../picorv32.v \
	$(FIRMWARE_BUILD_DIR)/icebreaker_fw_bram.hex | $(SYNTH_BUILD_DIR)
	yosys -f verilog -v3 -ql $(SYNTH_BUILD_DIR)/icebreaker.log \
	-p 'synth_ice40 -dsp -top icebreaker -json $(SYNTH_BUILD_DIR)/icebreaker.json' $(filter %.v,$^)

$(SYNTH_BUILD_DIR)/icebreaker_syn.v: $(SYNTH_BUILD_DIR)/icebreaker.json
	yosys -p 'read_json $<; write_verilog $@'

# ---- PNR ----
$(PNR_BUILD_DIR)/icebreaker.asc: icebreaker.pcf $(SYNTH_BUILD_DIR)/icebreaker.json | $(PNR_BUILD_DIR)
	nextpnr-ice40 --freq 13 --up5k --package sg48 --asc $@ --pcf icebreaker.pcf --json $(SYNTH_BUILD_DIR)/icebreaker.json

# ---- Bitstreams ----
$(BITSTREAM_BUILD_DIR)/icebreaker_flash.bin: $(PNR_BUILD_DIR)/icebreaker.asc | $(BITSTREAM_BUILD_DIR)
	icetime -d up5k -c 12 -mtr $(BITSTREAM_BUILD_DIR)/icebreaker.rpt $<
	icepack $< $@

$(BITSTREAM_BUILD_DIR)/icebreaker_bram.bin: $(PNR_BUILD_DIR)/icebreaker.asc | $(BITSTREAM_BUILD_DIR)
	icetime -d up5k -c 12 -mtr $(BITSTREAM_BUILD_DIR)/icebreaker.rpt $<
	icepack $< $@

# ---- Simulation ----
$(SIM_BUILD_DIR)/icebreaker_tb.vpp: icebreaker_tb.v icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v \
	picosoc.v ../picorv32.v spiflash.v | $(SIM_BUILD_DIR)
	iverilog -v -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS

$(SIM_BUILD_DIR)/icebreaker_syn_tb.vvp: icebreaker_tb.v $(SYNTH_BUILD_DIR)/icebreaker_syn.v spiflash.v | $(SIM_BUILD_DIR)
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS -DPOST_SYNTH_SIM

# ---- Testbench for SPI Flash Model ----
$(SIM_BUILD_DIR)/spiflash_tb.vvp: spiflash.v spiflash_tb.v | $(SIM_BUILD_DIR)
	iverilog -s testbench -o $@ $^

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

# ---- Clean ----

clean:
	rm -vrf $(BUILD_DIR)

.PHONY: spiflash_tb clean
.PHONY: prog_flash prog_bram prog_fw sim synsim
