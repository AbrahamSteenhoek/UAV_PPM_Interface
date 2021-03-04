library IEEE; use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.AlL;

entity shift_register_64bit is
	port(
		clk : in std_logic;
		reset : in std_logic;
		load : in std_logic;
		sin: in std_logic;
		d : in std_logic_vector(64-1 downto 0);
		q : out std_logic_vector(64-1 downto 0);
		sout: out std_logic);
end entity;

architecture mixed of shift_register_64bit is
	constant REG_SIZE : integer := 64;
	signal q_int: std_logic_vector(REG_SIZE-1 downto 0);
begin 
	process(clk)
	begin
	if clk'event and clk = '1' then
		if reset = '1' then 
			q_int <= (others => '0');
		elsif load = '1' then
			q_int <= d;
		else 
			q_int <= q_int(REG_SIZE-1-1 downto 0) & sin;
		end if;
	end if;
end process;

q <= q_int;
sout <= q_int(REG_SIZE-1);
end architecture;