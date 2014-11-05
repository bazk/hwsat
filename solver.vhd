library ieee;
use ieee.std_logic_1164.all;

entity solver is
    port (
        clk: in std_logic;
        reset: in std_logic
    );
end solver;

architecture behavioral of solver is
    component control_a
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
    end component;

    component control_b
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
    end component;

    component control_c
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
    end component;

    for control_a_0: control_a use entity work.control_a;
    for control_b_0: control_b use entity work.control_b;
    for control_c_0: control_c use entity work.control_c;

    signal gchange, gcontra, gclear: std_logic;

    signal lchange_a, lcontra_a, lclear_a: std_logic;
    signal lchange_b, lcontra_b, lclear_b: std_logic;
    signal lchange_c, lcontra_c, lclear_c: std_logic;

    signal var_a: std_logic_vector(0 to 1);
    signal var_b: std_logic_vector(0 to 1);
    signal var_c: std_logic_vector(0 to 1);

    signal channel0, channel1, channel2, channel3: std_logic;
    signal sat, unsat: std_logic;
begin
    control_a_0: control_a port map (
        clk => clk,
        reset => reset,
        lclear => lclear_a,
        lchange => lchange_a,
        lcontra => lcontra_a,
        gclear => gclear,
        gchange => gchange,
        gcontra => gcontra,
        var_a => var_a,
        var_b => var_b,
        var_c => var_c,
        eil => '1',
        eol => unsat,
        eor => channel0,
        eir => channel1
    );

    control_b_0: control_b port map (
        clk => clk,
        reset => reset,
        lclear => lclear_b,
        lchange => lchange_b,
        lcontra => lcontra_b,
        gclear => gclear,
        gchange => gchange,
        gcontra => gcontra,
        var_a => var_a,
        var_b => var_b,
        var_c => var_c,
        eil => channel0,
        eol => channel1,
        eor => channel2,
        eir => channel3
    );

    control_c_0: control_c port map (
        clk => clk,
        reset => reset,
        lclear => lclear_c,
        lchange => lchange_c,
        lcontra => lcontra_c,
        gclear => gclear,
        gchange => gchange,
        gcontra => gcontra,
        var_a => var_a,
        var_b => var_b,
        var_c => var_c,
        eil => channel2,
        eol => channel3,
        eor => sat,
        eir => '0'
    );

    gclear <= lclear_a or lclear_b or lclear_c;
    gchange <= lchange_a or lchange_b or lchange_c;
    gcontra <= lcontra_a or lcontra_b or lcontra_c;
end behavioral;