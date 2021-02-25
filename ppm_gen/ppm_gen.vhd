library IEEE;

use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity ppm_gen is
    port(
        RESET, CLK, EN : in std_logic;
        CHANNEL_DURATION : in std_logic_vector( 31 downto 0);
        PPM_OUT : out std_logic;
        CURRENT_CHANNEL : out std_logic( 3 downto 0 );
    );
end ppm_gen;

architecture behavior ppm_gen is
----------------------------------------------
--       Component declarations             --
----------------------------------------------
    component pulse_delay_up_counter_wReset_16bit is
        port(clk : in std_logic;
            reset : in std_logic;
            enable : in std_logic;
            count : out std_logic_vector(16-1 downto 0);
            count_trigger : out std_logic);
    end component;
    component frame_up_counter_wReset_24bit is
        port(clk : in std_logic;
            reset : in std_logic;
            enable : in std_logic;
            count : out std_logic_vector(24-1 downto 0);
            count_trigger : out std_logic);
    end component;

----------------------------------------------
--          Signal declarations             --
----------------------------------------------
    type state_type is ( TRANSMITTING_PULSE, CHANNEL_WAIT_IDLE );

    signal PS, NS : state_type;

    -- system outputs
    signal cur_channel_sig : std_logic_vector( 3 downto 0 ) := x"0";
    signal ppm_out_sig : std_logic := '1'; -- MP-1 has an active low ppm signal

    -- signals for pulse counter
    signal pulse_count_sig : std_logic_vector( 16-1 downto 0 );
    signal pulse_over_sig : std_logic := '0';
    signal pulse_counter_en_sig : std_logic := '0';

    -- signals for frame counter
    signal frame_count_sig : std_logic_vector(24-1 downto 0);
    signal frame_over_sig :  std_logic := '0';
    signal frame_reset_sig : std_logic := '0';
    -- signal frame_counter_en_sig : std_logic := '0';

    -- signals for channel duration counter
    signal channel_duration_count_sig : std_logic_vector(24-1 downto 0);
    signal channel_duration_over_sig : std_logic := '0';
    signal channel_counter_en_sig : std_logic := '0';
begin

    pulse_counter: entity pulse_delay_up_counter_wReset_16bit
    PORT MAP(
        clk => CLK,
        reset => RESET,
        enable => pulse_counter_en_sig,
        count => pulse_count_sig,
        count_trigger => pulse_over_sig
    );

    channel_duration_counter: entity generic_up_counter_wReset_24bit
    PORT MAP(
        clk => CLK,
        reset => RESET,
        enable => EN,
        count_value => CHANNEL_DURATION,
        count => channel_duration_count_sig,
        count_trigger => channel_duration_over_sig
    );

    frame_counter: entity frame_up_counter_wReset_24bit
    PORT MAP(
        clk => CLK,
        reset => frame_reset_sig,
        enable => EN,
        count => frame_count_sig,
        count_trigger => frame_over_sig
    );

    PPM_OUT <= ppm_out_sig;
    CURRENT_CHANNEL <= cur_channel_sig;

    reset_proc: process( RESET )
    begin
        if ( RESET OR frame_over_sig = '1' ) then
            -- frame always begins transmitting first channel
            PS <= CHANNEL_TRANSMITTING;
            NS <= CHANNEL_TRANSMITTING;

            cur_channel_sig <= (others => 0);
            ppm_out_sig <= '0'; -- PPM should be high because we're transmitting first channel

            pulse_counter_en_sig <= '1'; -- start timing the first pulse
        end if;
    end process reset_proc;

    sync_proc: process( CLK )
    begin
        if ( rising_edge( CLK ) and EN = '1' ) then
            PS <= NS;
        end if;
    end process sync_proc;

    comb_proc: process( PS )
    begin
        case PS is
            when TRANSMITTING_PULSE =>
                ppm_out_sig <= '0';
                pulse_counter_en_sig <= '1';

                if ( pulse_over_sig = '1' ) then
                    NS <= CHANNEL_WAIT_IDLE;
                else
                    NS <= TRANSMITTING_PULSE;
                end if;
            
            when CHANNEL_WAIT_IDLE =>
                ppm_out_sig <= '1';
                pulse_counter_en_sig <= '0';
                
                -- Only switch to transmitting pulse for channels 0-5
                -- Once cur_channel > 5, we have transmitted all channels, and remain idle until end of frame
                if ( channel_duration_over = '1' AND cur_channel_sig <= x"5" ) then
                    NS <= TRANSMITTING_PULSE; -- begin transmitting start of next channel

                    cur_channel_sig <= cur_channel_sig + 1;
                else
                    NS <= CHANNEL_WAIT_IDLE;
                end if;
            when

        end case;
    end process comb_proc;

end behavior;