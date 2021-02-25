library IEEE;

use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity ppm_gen_tb is
    port(
        my_in : in std_logic -- input needed to keep modelsim from complainning???
    );
end ppm_gen_tb;

architecture rtl of ppm_gen is
    component ppm_gen is
        port(
            RESET, CLK, EN : in std_logic;
            CHANNEL_DURATION : in std_logic_vector( 31 downto 0);
            PPM_OUT : out std_logic;
            CURRENT_CHANNEL : out std_logic( 3 downto 0 );
        );
    end component ppm_gen;

    signal clk_s : std_logic;
    signal reset_s : std_logic;
    signal enable_s : std_logic;
begin

    clk_gen: process
    begin
        clk <= '0';
        wait for 10 ns;
            loop
            wait for 1 ns;
            clk <= '1';
            wait for 1 ns;
            clk <= '0';
            end loop;
    end process clk_gen;
    
    
end rtl;