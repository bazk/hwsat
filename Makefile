WORKDIR = ./work
STOPTIME = 100ns

GHDL = ghdl
GHDLFLAGS = --workdir=$(WORKDIR)
GHDLRUNFLAGS = --stop-time=$(STOPTIME)

MAIN = solver


all: $(MAIN)_tb

run: $(MAIN)_tb.vcd

clean:
	$(GHDL) --remove $(GHDLFLAGS)
	rm -rf $(WORKDIR)/*.o
	rm -rf $(MAIN)_tb.vcd

# Elaboration target
$(MAIN)_tb: $(WORKDIR)/$(MAIN).o $(WORKDIR)/$(MAIN)_tb.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Run target
$(MAIN)_tb.vcd: $(MAIN)_tb
	$(GHDL) -r $(MAIN)_tb $(GHDLRUNFLAGS) --vcd=$@

# Targets to analyze files
$(WORKDIR)/$(MAIN).o: $(MAIN).vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/$(MAIN)_tb.o: $(MAIN)_tb.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/imp_a.o: imp_a.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/imp_b.o: imp_b.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/imp_c.o: imp_c.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

# Files dependences
$(WORKDIR)/$(MAIN).o: $(WORKDIR)/imp_a.o $(WORKDIR)/imp_b.o $(WORKDIR)/imp_c.o
$(WORKDIR)/$(MAIN)_tb.o: $(WORKDIR)/$(MAIN).o
