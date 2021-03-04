library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity down_counter_32bit_6reg is
	port(clk : in std_logic;
		reset : in std_logic;
		load : in std_logic;
		count_enable : in std_logic;
		reg_sel : in std_logic_vector(3-1 downto 0);
		reg_0 : in std_logic_vector(32-1 downto 0);
		reg_1 : in std_logic_vector(32-1 downto 0);
		reg_2 : in std_logic_vector(32-1 downto 0);
		reg_3 : in std_logic_vector(32-1 downto 0);
		reg_4 : in std_logic_vector(32-1 downto 0);
		reg_5 : in std_logic_vector(32-1 downto 0);		
		empty : out std_logic);
end down_counter_32bit_6reg;

architecture rtl of down_counter_32bit_6reg is
	signal count_s : std_logic_vector(32-1 downto 0);
begin
	process(clk, reset, load, count_enable, reg_sel, reg_0, reg_1, reg_2, reg_3, reg_4, reg_5)
	begin
	if(reset = '1') then
		count_s <= (others => '0');
		empty <= '0';
	elsif (rising_edge(clk)) then
		if (count_enable = '1' AND count_s > x"00009c40") then
			count_s <= count_s - 1;
		elsif(load = '1') then
			case reg_sel is
				when "000" =>
					count_s <= reg_0;
				when "001" => 
					count_s <= reg_1;
				when "010" =>
					count_s <= reg_2;
				when "011" =>
					count_s <= reg_3;
				when "100" =>
					count_s <= reg_4;
				when "101" => 
					count_s <= reg_5;
				when others =>
					count_s <= x"00009c40";
			end case;
		end if;
		if (count_s <= x"00009c40") then
			empty <= '1';
		else
			empty <= '0';
		end if;
	end if;
	end process;
end architecture;