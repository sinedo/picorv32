# Select your RISC-V compiler here (riscv32i/riscv32im/riscv32ic/riscv32imc)
RISCV_ISA = im

USE_MYSTDLIB = 1
TOOLCHAIN_PREFIX = /opt/riscv/bin/riscv-none-elf-

CFLAGS = -MD -O3 -mabi=ilp32 -march=rv32$(RISCV_ISA) -DTIME -DRISCV
OBJS = dhry_1.o dhry_2.o stdlib.o dhry_main.o

ifeq ($(USE_MYSTDLIB),1)
CFLAGS += -DUSE_MYSTDLIB -ffreestanding -nostdlib
OBJS += start.o
else
OBJS += syscalls.o
endif

test: testbench.vvp dhry.hex
	vvp -N testbench.vvp

test_la: testbench_la.vvp dhry.hex
	vvp -N testbench_la.vvp

size: dhry.elf
	$(TOOLCHAIN_PREFIX)size dhry.elf

dis: dhry.elf
	$(TOOLCHAIN_PREFIX)objdump -d dhry.elf

test_trace: testbench_la.vvp dhry.hex
	vvp -N $< +trace
	python3 ../showtrace.py testbench_la.trace dhry.elf > testbench_la.ins

timing: timing.txt
	grep '^##' timing.txt | gawk 'x != "" {print x,$$3-y;} {x=$$2;y=$$3;}' | sort | uniq -c | \
		gawk '{printf("%03d-%-7s %2d %-8s (%d)\n",$$3,$$2,$$3,$$2,$$1);}' | sort | cut -c13-

timing.txt: timing.vvp dhry.hex
	vvp -N timing.vvp > timing.txt

testbench_la.vvp: testbench_la.v ../picorv32.v
	iverilog -o testbench_la.vvp testbench_la.v ../picorv32.v
	chmod -x testbench_la.vvp

testbench.vvp: testbench.v ../picorv32.v
	iverilog -o testbench.vvp testbench.v ../picorv32.v
	chmod -x testbench.vvp

timing.vvp: testbench_la.v ../picorv32.v
	iverilog -o timing.vvp -DTIMING testbench_la.v ../picorv32.v
	chmod -x timing.vvp

dhry.hex: dhry.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

ifeq ($(USE_MYSTDLIB),1)
dhry.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections.lds,-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc
	chmod -x $@
else
dhry.elf: $(OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,../firmware/riscv.ld,-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc -lc
	chmod -x $@
endif

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

dhry_1.o dhry_2.o dhry_main.o: CFLAGS += -Wno-implicit-int -Wno-implicit-function-declaration

clean:
	rm -rf *.o *.d dhry.elf dhry.map dhry.bin dhry.hex testbench_la.vvp testbench_la.vcd timing.vvp timing.txt testbench_la.vvp testbench.vvp testbench.vcd

.PHONY: test clean size

-include *.d

