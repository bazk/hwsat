library ieee;
use ieee.std_logic_1164.all;

entity solver_tb is
end solver_tb;

architecture behavioral of solver_tb is
    component solver
        port (
            clk: in std_logic;
            reset: in std_logic;
            sat: out std_logic;
            unsat: out std_logic
        );
    end component;

    for solver_0: solver use entity work.solver;

    signal clk, reset, sat, unsat: std_logic := '0';
begin
    -- Instantiate solver
    solver_0: solver port map (
        clk => clk,
        reset => reset,
        sat => sat,
        unsat => unsat
    );

    -- 166Mhz clock ~= 5.74 ns full-period, 2.87 ns half-period
    clk <= '0' when (sat='1' or unsat='1') else not clk after 2.87 ns;
    reset <= '0', '1' after 2 ns, '0' after 7 ns;
end behavioral;