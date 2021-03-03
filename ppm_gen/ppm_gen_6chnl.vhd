library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ppm_gen_6chnl is
	port(clk : in std_logic;
	reset : in std_logic;
	enable : in std_logic;
	reg_0 : in std_logic_vector(32-1 downto 0);
	reg_1 : in std_logic_vector(32-1 downto 0);
	reg_2 : in std_logic_vector(32-1 downto 0);
	reg_3 : in std_logic_vector(32-1 downto 0);
	reg_4 : in std_logic_vector(32-1 downto 0);
	reg_5 : in std_logic_vector(32-1 downto 0);	
	ppm_out : out std_logic);
end ppm_gen_6chnl;

architecture mixed of ppm_gen_6chnl is

component down_counter_32bit_6reg 
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
end component;
component frame_up_counter_wReset_24bit 
	port(clk : in std_logic;
		reset : in std_logic;
		enable : in std_logic;
		count : out std_logic_vector(24-1 downto 0);
		count_trigger : out std_logic);
end component;
component pulse_delay_up_counter_wReset_16bit 
	port(clk : in std_logic;
		reset : in std_logic;
		enable : in std_logic;
		count : out std_logic_vector(16-1 downto 0);
		count_trigger : out std_logic);
end component;

signal load,count_enable,channel_empty : std_logic;
signal current_channel : std_logic_vector(3-1 downto 0);

signal pulse_delay_enable, pulse_delay_empty : std_logic;
signal pusle_delay_count : std_logic_vector(16-1 downto 0);

signal frame_time_counter_enable,  frame_time_counter_empty: std_logic;
signal frame_time_count : std_logic_vector(24-1 downto 0);

type state_type is (Gen, Pulse_Wait, Next_Channel, Frame_Wait);
signal state : state_type;

begin

	channel_down_counter: down_counter_32bit_6reg
	port map(clk, reset, load, count_enable, current_channel, reg_0, reg_1, reg_2, reg_3, reg_4, reg_5, channel_empty);
	
	pulse_delay : pulse_delay_up_counter_wReset_16bit
	port map(clk, reset, pulse_delay_enable, pusle_delay_count, pulse_delay_empty);
	
	frame_time_counter : frame_up_counter_wReset_24bit
	port map(clk, reset, frame_time_counter_enable, frame_time_count, frame_time_counter_empty);
	
	
	process(clk, enable, reset, reg_0, reg_1, reg_2, reg_3, reg_4, reg_5, frame_time_counter_empty, frame_time_counter_enable,pulse_delay_empty, channel_empty, current_channel)
	begin
	if reset = '1' then
	state <= Pulse_Wait;
	current_channel <= "000";
	load <= '1';
	ppm_out <= '0';
	pulse_delay_enable <= '0';
	count_enable <= '0';
	frame_time_counter_enable <= '0';
	elsif (rising_edge(clk) and enable = '1') then
		case state is
		when Pulse_Wait =>
			frame_time_counter_enable <= '1';
			ppm_out <= '0';
			pulse_delay_enable <= '1';
			if pulse_delay_empty = '1' and current_channel /= "110" then
				state <= Gen;
			elsif pulse_delay_empty = '1' and current_channel = "110" then
				state <= Frame_Wait;
			end if;
		when Gen =>
			ppm_out <= '1';
			count_enable <= '1';
			pulse_delay_enable <= '0';
			if channel_empty = '1' then
				count_enable<= '0';
				ppm_out <= '0';
				state <= Next_Channel;
			end if;
		when Next_Channel =>
			current_channel <= current_channel + 1;
			state <= Pulse_Wait;
		when Frame_Wait =>
			ppm_out <= '1';
			pulse_delay_enable <= '0';
			if frame_time_counter_empty = '1' then
				current_channel <= "000";
				state <= Pulse_Wait;
			end if;
		when others =>
			state <= Pulse_Wait;
			current_channel <= "000";
		end case;
	end if;
	end process;
end architecture;