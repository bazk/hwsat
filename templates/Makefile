WORKDIR = {{ work_dir | default('.') }}

GHDL = ghdl
GHDLFLAGS = {{ ghdl_flags }}

MAIN = solver


all: $(MAIN)_tb

clean:
	$(GHDL) --remove $(GHDLFLAGS)
	rm -f $(WORKDIR)/*.o

$(MAIN)_tb: $(MAIN).vhd $(MAIN)_tb.vhd {% for var in variables %}$(WORKDIR)/imp_{{ var.name }}.o $(WORKDIR)/control_{{ var.name }}.o {% endfor %}
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $(MAIN).vhd
	$(GHDL) -a $(GHDLFLAGS) $(MAIN)_tb.vhd
	$(GHDL) -e $(GHDLFLAGS) $@

{% for var in variables %}
$(WORKDIR)/imp_{{ var.name }}.o: imp_{{ var.name }}.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<

$(WORKDIR)/control_{{ var.name }}.o: control_{{ var.name }}.vhd
	@mkdir -p $(WORKDIR)
	$(GHDL) -a $(GHDLFLAGS) $<
{% endfor %}
