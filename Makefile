# ---- project config (edit per project) ----
TOP      := uart
DEVICE   := GW2AR-LV18QN88C8/I7
FAMILY   := GW2A-18C
BOARD    := tangnano20k

FILELIST := rtl.list
CST      := constraints/tangnano20k.cst
BUILD    := build

# ---- derived ----
SRCS := $(shell grep -vE '^[[:space:]]*(\#|$$)' $(FILELIST))
JSON := $(BUILD)/$(TOP).json
PNR  := $(BUILD)/$(TOP)_pnr.json
BIT  := $(BUILD)/$(TOP).fs

# ---- flow ----
.PHONY: all flash flash-spi clean
all: $(BIT)

$(JSON): $(SRCS) $(FILELIST) | $(BUILD)
	yosys -p "read_verilog $(SRCS); synth_gowin -top $(TOP) -json $@"

$(PNR): $(JSON) $(CST)
	nextpnr-himbaechel \
	    --json $< \
	    --write $@ \
	    --device $(DEVICE) \
	    --vopt family=$(FAMILY) \
	    --vopt cst=$(CST)

$(BIT): $(PNR)
	gowin_pack -d $(FAMILY) -o $@ $<

$(BUILD):
	mkdir -p $@

flash: $(BIT)
	openFPGALoader -b $(BOARD) $(BIT)

flash-spi: $(BIT)
	openFPGALoader -b $(BOARD) -f $(BIT)

clean:
	rm -rf $(BUILD)
