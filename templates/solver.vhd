library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity solver is
    port (
        clk: in std_logic;
        reset: in std_logic;
        sat: out std_logic;
        unsat: out std_logic
    );
end solver;

architecture behavioral of solver is
    {% for var in variables %}
    component control_{{ var.name }}
        port (
            clk: in std_logic;
            reset: in std_logic;
            lclear: out std_logic;
            lchange: out std_logic;
            lcontra: out std_logic;
            gclear: in std_logic;
            gchange: in std_logic;
            gcontra: in std_logic;
            {% for var2 in variables -%}
            {{ var2.name }}: inout std_logic_vector(0 to 1);
            {% endfor %}
            eil: in std_logic;
            eol: out std_logic;
            eir: in std_logic;
            eor: out std_logic;

            ldebug_num_decisions: out integer;
            ldebug_num_conflicts: out integer;
            ldebug_num_backtracks: out integer
        );
    end component;

    for control_{{ var.name }}_0: control_{{ var.name }} use entity work.control_{{ var.name }};

    signal lclear_{{ var.name }}, lchange_{{ var.name }}, lcontra_{{ var.name }}: std_logic;
    signal {{ var.name }}: std_logic_vector(0 to 1);

    signal channel_{{ loop.index }}_0, channel_{{ loop.index }}_1: std_logic;

    signal ldebug_num_decisions_{{ var.name }}, ldebug_num_conflicts_{{ var.name }}, ldebug_num_backtracks_{{ var.name }}: integer;
    {% endfor %}

    signal gclear, gchange, gcontra: std_logic;
    signal is_sat, is_unsat: std_logic;

    signal gdebug_num_decisions, gdebug_num_conflicts, gdebug_num_backtracks, gdebug_counter: integer;
begin
    {% for var in variables %}
    control_{{ var.name }}_0: control_{{ var.name }} port map (
        clk => clk,
        reset => reset,
        lclear => lclear_{{ var.name }},
        lchange => lchange_{{ var.name }},
        lcontra => lcontra_{{ var.name }},
        gclear => gclear,
        gchange => gchange,
        gcontra => gcontra,
        {% for var2 in variables -%}
        {{ var2.name }} => {{ var2.name }},
        {% endfor %}

        {% if loop.index > 1 %}
        eil => channel_{{ loop.index-1 }}_0,
        eol => channel_{{ loop.index-1 }}_1,
        {% else %}
        eil => '1',
        eol => is_unsat,
        {% endif %}

        {% if loop.index < len_variables %}
        eor => channel_{{ loop.index }}_0,
        eir => channel_{{ loop.index }}_1,
        {% else %}
        eor => is_sat,
        eir => '0',
        {% endif %}

        ldebug_num_decisions => ldebug_num_decisions_{{ var.name }},
        ldebug_num_conflicts => ldebug_num_conflicts_{{ var.name }},
        ldebug_num_backtracks => ldebug_num_backtracks_{{ var.name }}
    );
    {% endfor %}

    gclear <= {% for var in variables %} lclear_{{ var.name }} or{% endfor %} '0';
    gchange <= {% for var in variables %} lchange_{{ var.name }} or{% endfor %} '0';
    gcontra <= {% for var in variables %} lcontra_{{ var.name }} or{% endfor %} '0';

    sat <= is_sat;
    unsat <= is_unsat;

    process (clk, reset)
    begin
        if (reset='1') then
            gdebug_num_decisions <= 0;
            gdebug_num_conflicts <= 0;
            gdebug_num_backtracks <= 0;
            gdebug_counter <= 0;
        elsif (gdebug_counter >= 1024) then
            gdebug_num_decisions <= {% for var in variables %} ldebug_num_decisions_{{ var.name }} {% if not loop.last %}+{% endif %}{% endfor %};
            gdebug_num_conflicts <= {% for var in variables %} ldebug_num_conflicts_{{ var.name }} {% if not loop.last %}+{% endif %}{% endfor %};
            gdebug_num_backtracks <= {% for var in variables %} ldebug_num_backtracks_{{ var.name }} {% if not loop.last %}+{% endif %}{% endfor %};
            report "num_decisions = " & integer'image(gdebug_num_decisions);
            report "num_conflicts = " & integer'image(gdebug_num_conflicts);
            report "num_backtracks = " & integer'image(gdebug_num_backtracks);
            report " ";
            gdebug_counter <= 0;
        elsif (is_sat='1') then
            {% for var in variables %}
            if ({{ var.name }}="10") then
                report "{{ var.name }}";
            elsif ({{ var.name }}="01") then
                report "-{{ var.name }}";
            end if;
            {% endfor %}
            report " ";
        else
            gdebug_counter <= gdebug_counter + 1;
        end if;
    end process;
end behavioral;