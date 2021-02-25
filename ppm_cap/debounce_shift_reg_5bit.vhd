--
-- Samuel Ferguson
--


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use ieee.numeric_std.all;  

entity debounce_shift_reg_5bit is
    Port (clk : in  std_logic;
		reset : in std_logic;
        D   : in  std_logic;
        high_event : out std_logic;
		low_event : out std_logic);
end debounce_shift_reg_5bit;
    
architecture mixed of debounce_shift_reg_5bit is

    signal shift_reg_in : std_logic_vector(5-1 downto 0);
	signal load : std_logic;
	signal shift_reg_out : std_logic_vector(5-1 downto 0);
	type state_type is (Low_State, High_State);
	signal state : state_type;

component shift_register_5bit 
	port(
		clk : in std_logic;
		reset : in std_logic;
		load : in std_logic;
		sin: in std_logic;
		d : in std_logic_vector(5-1 downto 0);
		q : out std_logic_vector(5-1 downto 0);
		sout: out std_logic);
end component;	
	
	
begin

	shift_reg_5b : shift_register_5bit
	port map(clk, reset, load, D, shift_reg_in, shift_reg_out);


    process (clk, reset, D)
    begin
	if (reset = '1') then
		shift_reg_in <= "00000";
		load <= '1';
		state <= Low_State;
		high_event <= '0';
		low_event <= '1';
	elsif (rising_edge(clk)) then
		load <= '0';
		case state is
		when Low_State =>
			if(shift_reg_out = "11111") then
				state <= High_State;
				high_event <= '1';
				low_event <= '0';
			end if;
		when High_State =>
			if(shift_reg_out = "00000") then
				state <= Low_State;
				high_event <= '0';
				low_event <= '1';
			end if;
		when others =>
			state <= Low_State;
			high_event <= '0';
			low_event <= '1';
		end case;
	end if;
	end process;
end architecture;