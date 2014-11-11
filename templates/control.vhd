library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_{{ current_var.name }} is
    port (
        clk: in std_logic;
        reset: in std_logic;
        lclear: out std_logic;
        lchange: out std_logic;
        lcontra: out std_logic;
        gclear: in std_logic;
        gchange: in std_logic;
        gcontra: in std_logic;
        {% for var in variables %}
        {{ var.name }}: inout std_logic_vector(0 to 1);
        {% endfor %}
        eil: in std_logic;
        eol: out std_logic;
        eir: in std_logic;
        eor: out std_logic;

        ldebug_num_decisions: out integer;
        ldebug_num_conflicts: out integer;
        ldebug_num_backtracks: out integer
    );
end control_{{ current_var.name }};

architecture behavioral of control_{{ current_var.name }} is
    component imp_{{ current_var.name }}
        port (
            clk: in std_logic;
            reset: in std_logic;
            clear: in std_logic;
            change: out std_logic;
            contra: out std_logic;
            {% for var in variables %}
            {{ var.name }}: inout std_logic_vector(0 to 1);
            {% endfor %}
            value: in std_logic_vector(0 to 1)
        );
    end component;

    for imp_{{ current_var.name }}_0: imp_{{ current_var.name }} use entity work.imp_{{ current_var.name }};
    signal current_state: std_logic_vector(0 to 2);
    signal cur_var: std_logic_vector(0 to 1);

    signal debug_num_decisions: integer;
    signal debug_num_conflicts: integer;
    signal debug_num_backtracks: integer;
begin
    imp_{{ current_var.name }}_0: imp_{{ current_var.name }} port map (
        clk => clk,
        reset => reset,
        clear => gclear,
        change => lchange,
        contra => lcontra,
        {% for var in variables %}
        {{ var.name }} => {{ var.name }},
        {% endfor %}
        value => current_state(0 to 1)
    );

    cur_var <= {{ current_var.name }};

    ldebug_num_decisions <= debug_num_decisions;
    ldebug_num_conflicts <= debug_num_conflicts;
    ldebug_num_backtracks <= debug_num_backtracks;

    process (clk, reset)
    begin
        if (reset='1') then
            current_state <= "000"; -- init
            eol <= '0';
            eor <= '0';
            debug_num_decisions <= 0;
            debug_num_conflicts <= 0;
            debug_num_backtracks <= 0;
        elsif (rising_edge(clk)) then
            case current_state is
            when "000" => -- init
                if (eil='0' and eir='0') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '0';
                elsif (eir='1') then
                    eol <= '1';
                    eor <= '0';
                    lclear <= '0';
                elsif (eil='1' and (cur_var(0) or cur_var(1))='1') then
                    eol <= '0';
                    eor <= '1';
                    lclear <= '0';
                elsif (eil='1' and (cur_var(0) or cur_var(1))='0') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '0';
                    current_state <= "101"; -- active1

                    debug_num_decisions <= debug_num_decisions + 1;
                end if;
            when "101" => -- active1
                if (gchange='1' and gcontra='0') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '0';
                elsif (gcontra='1') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '1';
                    current_state <= "011"; -- active0

                    debug_num_conflicts <= debug_num_conflicts + 1;
                    debug_num_decisions <= debug_num_decisions + 1;
                elsif (gchange='0' and gcontra='0') then
                    eol <= '0';
                    eor <= '1';
                    lclear <= '0';
                    current_state <= "100"; -- passive1
                end if;
            when "100" => -- passive1
                if (eir='0') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '0';
                elsif (eir='1') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '1';
                    current_state <= "011"; -- active0

                    debug_num_decisions <= debug_num_decisions + 1;
                end if;
            when "011" => -- active0
                if (gchange='1') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '0';
                elsif (gcontra='1') then
                    eol <= '1';
                    eor <= '0';
                    lclear <= '0';
                    current_state <= "000"; -- init

                    debug_num_conflicts <= debug_num_conflicts + 1;
                    debug_num_backtracks <= debug_num_backtracks + 1;
                elsif (gchange='0' and gcontra='0') then
                    eol <= '0';
                    eor <= '1';
                    lclear <= '0';
                    current_state <= "010"; -- passive0
                end if;
            when "010" => -- passive0
                if (eir='0') then
                    eol <= '0';
                    eor <= '0';
                    lclear <= '0';
                elsif (eir='1') then
                    eol <= '1';
                    eor <= '0';
                    lclear <= '0';
                    current_state <= "000"; -- init

                    debug_num_backtracks <= debug_num_backtracks + 1;
                end if;
            when others =>
                current_state <= "000"; -- init
            end case;
        end if;
    end process;
end behavioral;