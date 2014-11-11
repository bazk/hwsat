WORKDIR = {{ work_dir | default('.') }}
STOPTIME = {{ stop_time | default('100ns') }}

GHDL = ghdl
GHDLFLAGS = {{ ghdl_flags }}
GHDLRUNFLAGS = {{ ghdl_run_flags }} --stop-time=$(STOPTIME)

MAIN = solver


all: $(MAIN)_tb

run: $(MAIN)_tb.vcd

clean:
	$(GHDL) --remove $(GHDLFLAGS)
	rm -f $(WORKDIR)/*.o
	rm -f $(MAIN)_tb.vcd

# Elaboration target
$(MAIN)_tb: $(WORKDIR)/$(MAIN).o $(WORKDIR)/$(MAIN)_tb.o
	$(GHDL) -e $(GHDLFLAGS) $@

# Run target
$(MAIN)_tb.vcd: $(MAIN)_tb
	$(GHDL) -r $(MAIN)_tb $(GHDLRUNFLAGS) --vcd=$@

# Targets to analyze files
$(WORKDIR)/$(MAIN).o: $(MAIN).vhd {% for var in variables %}$(WORKDIR)/imp_{{ var.name }}.o $(WORKDIR)/control_{{ var.name }}.o {% endfor %}
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/$(MAIN)_tb.o: $(MAIN)_tb.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<


{% for var in variables %}
$(WORKDIR)/imp_{{ var.name }}.o: imp_{{ var.name }}.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/control_{{ var.name }}.o: control_{{ var.name }}.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<
{% endfor %}
