library ieee;
use ieee.std_logic_1164.all;

entity imp_a is
    port (
        clear: in std_logic;
        reset: in std_logic;
        change: out std_logic;
        contra: out std_logic;
        var_a: inout std_logic_vector(0 to 1);
        var_b: inout std_logic_vector(0 to 1);
        var_c: inout std_logic_vector(0 to 1);
        value: in std_logic_vector(0 to 1)
    );
end imp_a;

architecture behavioral of imp_a is
    signal nxt: std_logic_vector(0 to 1);
    signal cur: std_logic_vector(0 to 1);
begin
    process (clear, reset)
    begin
        if (reset='1') then
            cur <= "00";
        elsif (rising_edge(clear)) then
            cur <= nxt;
        end if;
    end process;

    var_a <= cur;

    nxt(0) <= value(0) or (var_b(1) or var_c(0));
    nxt(1) <= value(1) or '0';

    change <= (nxt(0) xor cur(0)) or (nxt(1) xor cur(1));
    contra <= cur(0) and cur(1);
end behavioral;

--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity control_a is
    port (
        clk: in std_logic;
        reset: in std_logic;
        lclear: out std_logic;
        lchange: out std_logic;
        lcontra: out std_logic;
        gclear: in std_logic;
        gchange: in std_logic;
        gcontra: in std_logic;
        var_a: inout std_logic_vector(0 to 1);
        var_b: inout std_logic_vector(0 to 1);
        var_c: inout std_logic_vector(0 to 1);
        eil: in std_logic;
        eol: out std_logic;
        eir: in std_logic;
        eor: out std_logic
    );
end control_a;

architecture behavioral of control_a is
    component imp_a
        port (
            clear: in std_logic;
            reset: in std_logic;
            change: out std_logic;
            contra: out std_logic;
            var_a: inout std_logic_vector(0 to 1);
            var_b: inout std_logic_vector(0 to 1);
            var_c: inout std_logic_vector(0 to 1);
            value: in std_logic_vector(0 to 1)
        );
    end component;

    for imp_a_0: imp_a use entity work.imp_a;

    --type state_type is (init, active0, passive0, active1, passive1);
    --signal current_state, current_state: state_type;
    signal current_state, next_state: std_logic_vector(0 to 2);

    signal cur_var: std_logic_vector(0 to 1);

    signal value: std_logic_vector(0 to 1);
begin
    imp_a_0: imp_a port map (
        clear => clk,
        reset => reset,
        change => lchange,
        contra => lcontra,
        var_a => var_a,
        var_b => var_b,
        var_c => var_c,
        value => value
    );

    cur_var <= var_a;

    process (clk, reset)
    begin
        if (reset='1') then
            value <= "00";
            current_state <= "000"; -- init
        elsif (rising_edge(clk)) then
            case current_state is
            when "000" => -- init
                if (eil='0' and eir='0') then
                    eol <= '0';
                    eor <= '0';
                elsif (eir='1') then
                    eol <= '1';
                    eor <= '0';
                elsif (eil='1' and (cur_var(0) or cur_var(1))='1') then
                    eol <= '0';
                    eor <= '1';
                elsif (eil='1' and (cur_var(0) or cur_var(1))='0') then
                    eol <= '0';
                    eor <= '0';
                    current_state <= "001"; -- active1
                end if;
            when "001" => -- active1
                value <= "10";

                if (gchange='1' and gcontra='0') then
                    eol <= '0';
                    eor <= '0';
                elsif (gcontra='1') then
                    eol <= '0';
                    eor <= '0';
                    current_state <= "011"; -- active0
                elsif (gchange='0' and gcontra='0') then
                    eol <= '0';
                    eor <= '1';
                    current_state <= "010"; -- passive1
                end if;
            when "010" => -- passive1
                if (eir='0') then
                    eol <= '0';
                    eor <= '0';
                elsif (eir='1') then
                    eol <= '0';
                    eor <= '0';
                    current_state <= "011"; -- active0
                end if;
            when "011" => -- active0
                value <= "01";

                if (gchange='1' and gcontra='0') then
                    eol <= '0';
                    eor <= '0';
                elsif (gchange='0' and gcontra='0') then
                    eol <= '0';
                    eor <= '1';
                    current_state <= "100"; -- passive0
                elsif (gcontra='1') then
                    eol <= '1';
                    eor <= '0';
                    current_state <= "000"; -- init
                end if;
            when "100" => -- passive0
                if (eir='0') then
                    eol <= '0';
                    eor <= '0';
                elsif (eir='1') then
                    eol <= '1';
                    eor <= '0';
                    current_state <= "000"; -- init
                end if;
            when others =>
                current_state <= "000"; -- init
            end case;
        end if;
    end process;
end behavioral;