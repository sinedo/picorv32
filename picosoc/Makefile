# Select your RISC-V compiler here (riscv32i/riscv32im/riscv32ic/riscv32imc)
RISCV_ISA = i

CROSS = /opt/riscv/bin/riscv-none-elf-
CFLAGS= -O3 -march=rv32$(RISCV_ISA)

DHRY_SRCS = dhrystone/dhry.h dhrystone/stdlib.c dhrystone/dhry_2.c dhrystone/dhry_1.c
BRAM_SIZE = 3072

# ---- Firmware analysis ----

size: icebreaker_fw.elf
	$(CROSS)size icebreaker_fw.elf

dis: icebreaker_fw.elf
	$(CROSS)objdump -d icebreaker_fw.elf

disdump: icebreaker_fw.elf
	$(CROSS)objdump -D icebreaker_fw.elf > icebreaker_fw.s

# ---- iCE40 IceBreaker Board ----

sim: icebreaker_tb.vvp icebreaker_fw.hex icebreaker_fw_bram.hex
	vvp -N $< +firmware=icebreaker_fw.hex

synsim: icebreaker_syn_tb.vvp icebreaker_fw.hex
	vvp -N $< +firmware=icebreaker_fw.hex

icebreaker.json: icebreaker.v spimemio.v simpleuart.v picosoc.v ice40up5k_spram.v ../picorv32.v icebreaker_fw_bram.hex
	yosys -f verilog -v3 -ql icebreaker.log -p 'synth_ice40 -dsp -top icebreaker -json icebreaker.json'  $(filter %.v, $^)

icebreaker_tb.vvp: icebreaker_tb.v icebreaker.v ice40up5k_spram.v spimemio.v simpleuart.v picosoc.v ../picorv32.v spiflash.v
	iverilog -v -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS

icebreaker_syn_tb.vvp: icebreaker_tb.v icebreaker_syn.v spiflash.v
	iverilog -s testbench -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v` -DNO_ICE40_DEFAULT_ASSIGNMENTS

icebreaker_syn.v: icebreaker.json
	yosys -p 'read_json icebreaker.json; write_verilog icebreaker_syn.v'

icebreaker.asc: icebreaker.pcf icebreaker.json
	nextpnr-ice40 --freq 13 --up5k --package sg48 --asc icebreaker.asc --pcf icebreaker.pcf --json icebreaker.json

# This requires a reset address of 0x0010_0000 and the .text section mapped to FLASH in the linker script
icebreaker_flash.bin: icebreaker.asc
	icetime -d up5k -c 12 -mtr icebreaker.rpt icebreaker.asc
	icepack icebreaker.asc icebreaker_flash.bin

icebreaker_bram.bin: icebreaker.asc
	icetime -d up5k -c 12 -mtr icebreaker.rpt icebreaker.asc
	icepack icebreaker.asc icebreaker_bram.bin

prog_flash: icebreaker_flash.bin icebreaker_fw.bin
	iceprog icebreaker_flash.bin
	iceprog -o 1M icebreaker_fw.bin

prog_bram: icebreaker_bram.bin
	iceprog icebreaker_bram.bin

prog_fw: icebreaker_fw.bin
	iceprog -o 1M icebreaker_fw.bin

icebreaker_sections.lds: sections.lds
	$(CROSS)cpp -P -DICEBREAKER -o $@ $^

icebreaker_fw.elf: icebreaker_sections.lds start.s firmware.c $(DHRY_SRCS)
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -DTIME -DRISCV -DUSE_MYSTDLIB -ffreestanding -nostdlib -mabi=ilp32 -march=rv32$(RISCV_ISA) -Wl,-Bstatic,-T,icebreaker_sections.lds,-Map,icebreaker_fw.map,--strip-debug -o icebreaker_fw.elf start.s firmware.c $(DHRY_SRCS) -Wno-implicit-int -Wno-implicit-function-declaration -lgcc

icebreaker_fw.hex: icebreaker_fw.elf
	$(CROSS)objcopy -O verilog icebreaker_fw.elf icebreaker_fw.hex

icebreaker_fw_bram.hex: icebreaker_fw.bin
	python3 ../firmware/makehex.py $< $(BRAM_SIZE) > $@

icebreaker_fw.bin: icebreaker_fw.elf
	$(CROSS)objcopy -O binary icebreaker_fw.elf icebreaker_fw.bin

icebreaker_fw_random.hex:
	icebram -g 32 $(BRAM_SIZE) > icebreaker_fw_random.hex

icebreaker_bram.asc: icebreaker_fw_bram.hex icebreaker_fw_random.hex icebreaker.asc
	icebram -v icebreaker_fw_random.hex icebreaker_fw_bram.hex < icebreaker.asc > icebreaker_bram.asc

# ---- Testbench for SPI Flash Model ----

spiflash_tb: spiflash_tb.vvp icebreaker_fw.hex
	vvp -N $< +firmware=icebreaker_fw.hex

spiflash_tb.vvp: spiflash.v spiflash_tb.v
	iverilog -s testbench -o $@ $^

# ---- Clean ----

clean:
	rm -f testbench.vvp testbench.vcd spiflash_tb.vvp spiflash_tb.vcd
	rm -f icebreaker_fw.elf icebreaker_fw.hex icebreaker_fw.bin icebreaker_fw.map icebreaker_fw.d
	rm -f icebreaker.json icebreaker.log icebreaker.asc icebreaker.rpt icebreaker_flash.bin
	rm -f icebreaker_syn.v icebreaker_syn_tb.vvp icebreaker_tb.vvp
	rm -f icebreaker_fw_random.hex icebreaker_bram.asc icebreaker_bram.bin icebreaker_fw_bram.hex
	rm -f icebreaker_fw.s icebreaker_sections.lds

.PHONY: spiflash_tb clean
.PHONY: prog_flash prog_bram prog_fw sim synsim
