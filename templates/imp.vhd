library ieee;
use ieee.std_logic_1164.all;

entity imp_{{ current_var.name }} is
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
end imp_{{ current_var.name }};

architecture behavioral of imp_{{ current_var.name }} is
    signal imp: std_logic_vector(0 to 1);
    signal nxt: std_logic_vector(0 to 1);
    signal cur: std_logic_vector(0 to 1);
begin
    process (clk, reset, clear)
    begin
        if (reset='1') then
            cur <= "00";
        elsif (clear='1') then
            cur <= "00";
        elsif (rising_edge(clk)) then
            cur <= nxt;
        end if;
    end process;

    {{ current_var.name }} <= cur;

    imp(0) <= {{ current_var.pos_implications }};
    imp(1) <= {{ current_var.neg_implications }};

    nxt(0) <= value(0) or imp(0);
    nxt(1) <= value(1) or imp(1);

    change <= (nxt(0) xor cur(0)) or (nxt(1) xor cur(1));
    contra <= cur(0) and cur(1);
end behavioral;