library ieee;
use ieee.std_logic_1164.all;

entity solver_tb is
end solver_tb;

architecture behavioral of solver_tb is
    component solver
        port (
            clk: in std_logic;
            reset: in std_logic
        );
    end component;

    for solver_0: solver use entity work.solver;

    signal clk, reset: std_logic;

    procedure clock_gen(signal clk: out std_logic; constant freq: real) is
        constant period: time := 1 sec / freq;
        constant high_time: time := period / 2;
        constant low_time: time := period - high_time;
    begin
        -- sanity check
        assert (high_time /= 0 fs)
            report "clk_plain: High time is zero; time resolution to large for frequency"
            severity failure;

        -- Generate a clock cycle
        loop
            clk <= '1';
            wait for HIGH_TIME;
            clk <= '0';
            wait for LOW_TIME;
        end loop;
    end procedure;
begin
    -- Instantiate solver
    solver_0: solver port map (
        clk => clk,
        reset => reset
    );

    -- Generate a 166.667MHz clock and reset the circuit
    clock_gen(clk, 166.667E6);
    reset <= '0', '1' after 2 ns, '0' after 10 ns;
end behavioral;