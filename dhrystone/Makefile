# Select your RISC-V compiler here (riscv32i/riscv32im/riscv32ic/riscv32imc)
RISCV_ISA = im

USE_MYSTDLIB = 1
TOOLCHAIN_PREFIX = /opt/riscv/bin/riscv-none-elf-

BUILD_DIR := build

CFLAGS = -MD -O3 -mabi=ilp32 -march=rv32$(RISCV_ISA) -DTIME -DRISCV
OBJS = dhry_1.o dhry_2.o stdlib.o dhry_main.o
OBJS := $(addprefix $(BUILD_DIR)/,$(OBJS))

ifeq ($(USE_MYSTDLIB),1)
	CFLAGS += -DUSE_MYSTDLIB -ffreestanding -nostdlib
	OBJS := $(BUILD_DIR)/start.o $(OBJS)
else
	OBJS += $(BUILD_DIR)/syscalls.o
endif

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test: $(BUILD_DIR)/testbench.vvp $(BUILD_DIR)/dhry.hex
	vvp -N $(BUILD_DIR)/testbench.vvp

test_la: $(BUILD_DIR)/testbench_la.vvp $(BUILD_DIR)/dhry.hex
	vvp -N $(BUILD_DIR)/testbench_la.vvp

size: $(BUILD_DIR)/dhry.elf
	$(TOOLCHAIN_PREFIX)size $(BUILD_DIR)/dhry.elf

dis: $(BUILD_DIR)/dhry.elf
	$(TOOLCHAIN_PREFIX)objdump -d $(BUILD_DIR)/dhry.elf

test_trace: $(BUILD_DIR)/testbench_la.vvp $(BUILD_DIR)/dhry.hex
	vvp -N $< +trace
	python3 ../showtrace.py $(BUILD_DIR)/testbench.trace $(BUILD_DIR)/dhry.elf > $(BUILD_DIR)/testbench_la.ins

timing: $(BUILD_DIR)/timing.txt
	grep '^##' $(BUILD_DIR)/timing.txt | gawk 'x != "" {print x,$$3-y;} {x=$$2;y=$$3;}' | sort | uniq -c | \
		gawk '{printf("%03d-%-7s %2d %-8s (%d)\n",$$3,$$2,$$3,$$2,$$1);}' | sort | cut -c13-

$(BUILD_DIR)/timing.txt: $(BUILD_DIR)/timing.vvp $(BUILD_DIR)/dhry.hex
	vvp -N $(BUILD_DIR)/timing.vvp > $(BUILD_DIR)/timing.txt

$(BUILD_DIR)/testbench_la.vvp: testbench_la.v ../picorv32.v | $(BUILD_DIR)
	iverilog -o $(BUILD_DIR)/testbench_la.vvp testbench_la.v ../picorv32.v
	chmod -x $(BUILD_DIR)/testbench_la.vvp

$(BUILD_DIR)/testbench.vvp: testbench.v ../picorv32.v | $(BUILD_DIR)
	iverilog -o $(BUILD_DIR)/testbench.vvp testbench.v ../picorv32.v
	chmod -x $(BUILD_DIR)/testbench.vvp

$(BUILD_DIR)/timing.vvp: testbench_la.v ../picorv32.v | $(BUILD_DIR)
	iverilog -o $(BUILD_DIR)/timing.vvp -DTIMING testbench_la.v ../picorv32.v
	chmod -x $(BUILD_DIR)/timing.vvp

$(BUILD_DIR)/dhry.hex: $(BUILD_DIR)/dhry.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

ifeq ($(USE_MYSTDLIB),1)
$(BUILD_DIR)/dhry.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) \
  	-Wl,-Bstatic,-T,sections.lds,-Map,$(BUILD_DIR)/dhry.map,--strip-debug \
  	-o $@ $(OBJS) -lgcc
else
$(BUILD_DIR)/dhry.elf: $(OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,../firmware/riscv.ld,-Map,$(BUILD_DIR)/dhry.map,--strip-debug -o $@ $(OBJS) -lgcc -lc
	chmod -x $@
endif

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) -MMD -MP -MF $(BUILD_DIR)/$*.d -o $@ $<

$(BUILD_DIR)/%.o: %.S | $(BUILD_DIR)
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) -MMD -MP -MF $(BUILD_DIR)/$*.d -o $@ $<

$(BUILD_DIR)/dhry_1.o \
$(BUILD_DIR)/dhry_2.o \
$(BUILD_DIR)/dhry_main.o: CFLAGS += -Wno-implicit-int -Wno-implicit-function-declaration

clean:
	rm -rf $(BUILD_DIR)

.PHONY: test clean size

-include $(BUILD_DIR)/*.d

