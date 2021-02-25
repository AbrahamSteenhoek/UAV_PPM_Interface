--
-- Samuel Ferguson
--
--Resets count when reset is equal to 1
--Outputs 1 at count_trigger when 200k clk cycles pass
--Or 20ms has passed

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity frame_up_counter_wReset_24bit is
	port(clk : in std_logic;
		reset : in std_logic;
		enable : in std_logic;
		channel
		count : out std_logic_vector(24-1 downto 0);
		count_trigger : out std_logic);
end frame_up_counter_wReset_24bit;

architecture dataflow of frame_up_counter_wReset_24bit is
	signal count_s : std_logic_vector(24-1 downto 0);
begin
	process(clk, reset, enable)
	begin
	if(reset = '1') then
		count_s <= (others => '0');
		count_trigger <= '0';
	elsif (rising_edge(clk)) then
		if (enable = '1') then
			count_s <= count_s + 1;
		end if;
		if (count_s = x"1e8480") then
			count_trigger <= '1';
			count_s <= x"000000";
		else
			count_trigger <= '0';
		end if;
	end if;
	end process;
	count <= count_s;
	
end architecture;