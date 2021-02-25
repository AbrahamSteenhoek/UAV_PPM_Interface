library IEEE;

use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity ppm_cap_tb is
    port(
        my_in : in std_logic -- input needed to keep modelsim from complainning???
    );
end ppm_cap_tb;

architecture rtl of ppm_cap_tb is
    component ppm_cap is
    port (  
        CLK, RESET, EN : in std_logic;
        PPM_INPUT : in std_logic;
        CHANNEL_COUNT : out std_logic_vector( 31 downto 0 );
        CHANNEL : out std_logic_vector( 2 downto 0 );
        WRITE_EN : out std_logic;
        END_OF_FRAME : out std_logic;
        Y : out std_logic_vector( 1 downto 0) );

    end component ppm_cap;

    constant clk_period : time := 10ns;
    constant pulse_width: time := 400us;
    constant channel_counter_rst_val : std_logic_vector( 31 downto 0 ) := x"00000005";

    constant IDLE : std_logic_vector( 1 downto 0 ) := "00";
    constant NEW_CHANNEL_PULSE: std_logic_vector( 1 downto 0 ) := "01";
    constant CHANNEL_TRANSMITTING : std_logic_vector( 1 downto 0 ) := "10";

    signal clk_s : std_logic := '0';
    signal reset_s : std_logic := '1';
    signal enable_s : std_logic := '0';

    signal i_ppm_input : std_logic := '1';
    signal o_channel_count : std_logic_vector ( 31 downto 0 );
    signal o_channel : std_logic_vector (2 downto 0);
    signal o_write_en : std_logic;
    signal o_end_of_frame : std_logic;
    signal o_ppm_cap_cur_state : std_logic_vector(1 downto 0);
begin

    dut: ppm_cap
    PORT MAP(
        CLK => clk_s,
        RESET => reset_s,
        EN => enable_s,
        PPM_INPUT => i_ppm_input,
        CHANNEL_COUNT => o_channel_count,
        CHANNEL => o_channel,
        WRITE_EN => o_write_en,
        END_OF_FRAME => o_end_of_frame,
        Y => o_ppm_cap_cur_state
    );

    -- clk_gen: process
    --     clk_s <= not clk_s after ( clk_period / 2 );
    -- end process clk_gen;
    clk_gen: process
    begin
        wait for ( clk_period / 2 );
        clk_s <= '1';
        wait for ( clk_period / 2 );
        clk_s <= '0';
    end process clk_gen;

    DUT_stimulus: process
    begin
        reset_s <= '0';
        enable_s <= '1';

        wait for 500000ns;
        assert( ( o_channel_count = channel_counter_rst_val ) and ( o_channel = x"0" ) and ( o_write_en = '0' ) and ( o_end_of_frame = '1' ) and ( o_ppm_cap_cur_state = IDLE ) )
        report "assert failed for init setup" severity error;
        wait for 500000ns;

        -- Channel 0 pulse - 1463us
        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        wait for pulse_width;
        -- 0x9C41 is 40,000
        assert(o_channel_count = x"9C40" - x"1")
        report "ASSERT FAILED: CH0 pulse test - channel_count" severity error;
        assert( o_channel = x"0" )
        report "ASSERT FAILED: CH0 pulse test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH0 pulse test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH0 pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = NEW_CHANNEL_PULSE )
        report "ASSERT FAILED: CH0 pulse test - cur_state" severity error;

        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        -- rest of Channel 0 duration
        i_ppm_input <= '1';
        wait for 1063us;
        assert(o_channel_count = x"23B7C" - x"1" + x"14") -- add the delay from the bouncing signal
        report "ASSERT FAILED: CH0 duration test - channel_count" severity error;
        assert( o_channel = x"0" )
        report "ASSERT FAILED: CH0 duration test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH0 duration test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH0 duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = CHANNEL_TRANSMITTING )
        report "ASSERT FAILED: CH0 duration test - cur_state" severity error;

        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        -- Channel 1 pulse - 1443us
        i_ppm_input <= '0';
        wait for pulse_width;
        assert(o_channel_count = x"9C40" - x"1")
        report "ASSERT FAILED: CH1 pulse test - channel_count" severity error;
        assert( o_channel = x"1" )
        report "ASSERT FAILED: CH1 pulse test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH1 pulse test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH1 pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = NEW_CHANNEL_PULSE )
        report "ASSERT FAILED: CH1 pulse test - cur_state" severity error;

        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        -- rest of Channel 1 duration
        i_ppm_input <= '1';
        wait for 1043us;
        assert(o_channel_count = x"233AC" - x"1" + x"14")
        report "ASSERT FAILED: CH1 duration test - channel_count" severity error;
        assert( o_channel = x"1" )
        report "ASSERT FAILED: CH1 duration test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH1 duration test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH1 duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = CHANNEL_TRANSMITTING )
        report "ASSERT FAILED: CH1 duration test - cur_state" severity error;

        -- Channel 2 pulse - 1804us
        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        i_ppm_input <= '0';
        wait for pulse_width;
        assert(o_channel_count = x"9C40" - x"1")
        report "ASSERT FAILED: CH2 pulse test - channel_count" severity error;
        assert( o_channel = x"2" )
        report "ASSERT FAILED: CH2 pulse test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH2 pulse test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH2 pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = NEW_CHANNEL_PULSE )
        report "ASSERT FAILED: CH2 pulse test - cur_state" severity error;

        -- rest of Channel 2 duration
        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        i_ppm_input <= '1';
        wait for 1404us;
        assert(o_channel_count = x"2C0B0" - x"1" + x"14")
        report "ASSERT FAILED: CH2 duration test - channel_count" severity error;
        assert( o_channel = x"2" )
        report "ASSERT FAILED: CH2 duration test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH2 duration test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH2 duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = CHANNEL_TRANSMITTING )
        report "ASSERT FAILED: CH2 duration test - cur_state" severity error;

        -- Channel 3 pulse - 1553us
        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        i_ppm_input <= '0';
        wait for pulse_width;
        assert(o_channel_count = x"9C40" - x"1")
        report "ASSERT FAILED: CH3 pulse test - channel_count" severity error;
        assert( o_channel = x"3" )
        report "ASSERT FAILED: CH3 pulse test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH3 pulse test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH3 pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = NEW_CHANNEL_PULSE )
        report "ASSERT FAILED: CH3 pulse test - cur_state" severity error;

        -- rest of Channel 3 duration
        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        i_ppm_input <= '1';
        wait for 1153us;
        assert(o_channel_count = x"25EA4" - x"1" + x"14")
        report "ASSERT FAILED: CH3 duration test - channel_count" severity error;
        assert( o_channel = x"3" )
        report "ASSERT FAILED: CH3 duration test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH3 duration test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH3 duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = CHANNEL_TRANSMITTING )
        report "ASSERT FAILED: CH3 duration test - cur_state" severity error;

        -- Channel 4 pulse - 1243us
        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        i_ppm_input <= '0';
        wait for pulse_width;
        assert(o_channel_count = x"9C40" - x"1")
        report "ASSERT FAILED: CH4 pulse test - channel_count" severity error;
        assert( o_channel = x"4" )
        report "ASSERT FAILED: CH4 pulse test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH4 pulse test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH4 pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = NEW_CHANNEL_PULSE )
        report "ASSERT FAILED: CH4 pulse test - cur_state" severity error;

        -- rest of Channel 4 duration
        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        i_ppm_input <= '1';
        wait for 843us;
        assert(o_channel_count = x"1E58C" - x"1" + x"14")
        report "ASSERT FAILED: CH4 duration test - channel_count" severity error;
        assert( o_channel = x"4" )
        report "ASSERT FAILED: CH4 duration test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH4 duration test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH4 duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = CHANNEL_TRANSMITTING )
        report "ASSERT FAILED: CH4 duration test - cur_state" severity error;

        -- Channel 5 pulse - 1744us
        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        i_ppm_input <= '0';
        wait for pulse_width;
        assert(o_channel_count = x"9C40" - x"1")
        report "ASSERT FAILED: CH5 pulse test - channel_count" severity error;
        assert( o_channel = x"5" )
        report "ASSERT FAILED: CH5 pulse test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH5 pulse test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH5 pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = NEW_CHANNEL_PULSE )
        report "ASSERT FAILED: CH5 pulse test - cur_state" severity error;

        -- rest of Channel 5 duration
        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        i_ppm_input <= '1';
        wait for 1344us;
        assert(o_channel_count = x"2A940" - x"1" + x"14")
        report "ASSERT FAILED: CH5 duration test - channel_count" severity error;
        assert( o_channel = x"5" )
        report "ASSERT FAILED: CH5 duration test - cur_channel" severity error;
        assert( o_write_en = '1' )
        report "ASSERT FAILED: CH5 duration test - write_en" severity error;
        assert( o_end_of_frame = '0' )
        report "ASSERT FAILED: CH5 duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = CHANNEL_TRANSMITTING )
        report "ASSERT FAILED: CH5 duration test - cur_state" severity error;

        -- IDLE pulse
        -- add a bounce in the signal (pulse has started)
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';

        i_ppm_input <= '0';
        wait for pulse_width;
        assert(o_channel_count = channel_counter_rst_val)
        report "ASSERT FAILED: IDLE pulse test - channel_count" severity error;
        assert( o_channel = x"0" )
        report "ASSERT FAILED: IDLE pulse test - cur_channel" severity error;
        assert( o_write_en = '0' )
        report "ASSERT FAILED: IDLE pulse test - write_en" severity error;
        assert( o_end_of_frame = '1' )
        report "ASSERT FAILED: IDLE pulse test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = IDLE )
        report "ASSERT FAILED: IDLE pulse test - cur_state" severity error;

        -- IDLE duration
        -- add a bounce in the signal (pulse is done)
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';
        wait for 25ns;
        i_ppm_input <= '0';
        wait for 25ns;
        i_ppm_input <= '1';

        i_ppm_input <= '1';
        wait for 975us;
        assert(o_channel_count = channel_counter_rst_val)
        report "ASSERT FAILED: IDLE duration test - channel_count" severity error;
        assert( o_channel = x"0" )
        report "ASSERT FAILED: IDLE duration test - cur_channel" severity error;
        assert( o_write_en = '0' )
        report "ASSERT FAILED: IDLE duration test - write_en" severity error;
        assert( o_end_of_frame = '1' )
        report "ASSERT FAILED: IDLE duration test - end_of_frame" severity error;
        assert(o_ppm_cap_cur_state = IDLE )
        report "ASSERT FAILED: IDLE duration test - cur_state" severity error;



        wait;
        
    end process DUT_stimulus;
    
    
end rtl;
