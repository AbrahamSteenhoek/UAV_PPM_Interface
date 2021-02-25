library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;

entity ppm_cap is
    port (  
        CLK, RESET, EN : in std_logic;
        PPM_INPUT : in std_logic;
        CHANNEL_COUNT : out std_logic_vector( 31 downto 0 );
        CHANNEL : out std_logic_vector( 2 downto 0 );
        WRITE_EN : out std_logic;
        END_OF_FRAME : out std_logic;
        Y : out std_logic_vector( 1 downto 0) );

end ppm_cap;

architecture behavior of ppm_cap is
    -- IDLE: All channels have finished transmitting. Waiting for start of next frame
    -- NEW_CHANNEL_PULSE: New channel has begun transmitting, which is signaled with a 400us pulse
    -- CHANNEL_TRANSMITTING: Pulse indicating new channel is over, but channel is still transmitting
    type state_type is ( CHANNEL_TRANSMITTING, NEW_CHANNEL_PULSE, IDLE );

    signal PS, NS, PrevS : state_type;

    signal cur_channel_sig : std_logic_vector( 2 downto 0 ) := "000";
    signal cur_channel_counter_reset_sig : std_logic := '1';
    signal cur_channel_counter_en_sig : std_logic := '0';

    signal cur_channel_sig2 : std_logic_vector( 2 downto 0 ) := "000";

    signal write_en_sig : std_logic := '0';
    signal end_of_frame_sig : std_logic := '0';

    signal counter_reset_sig : std_logic := '1';
    signal counter_inc_sig : std_logic := '0';
    signal channel_count_sig : std_logic_vector( 31 downto 0 ) := x"00000000";
begin
    CHANNEL_COUNT <= channel_count_sig;
    CHANNEL <= cur_channel_sig;
    WRITE_EN <= write_en_sig;
    END_OF_FRAME <= end_of_frame_sig;

    sync_proc: process( CLK, RESET )
    begin
        if ( RESET = '1' ) then
            PS <= IDLE;

            -- cur_channel_sig <= (others => '0');
        elsif ( rising_edge( CLK ) and EN = '1' ) then
            PrevS <= PS;
            PS <= NS;

        end if;
    end process sync_proc;

    comb_proc: process( PS, PPM_INPUT )
    begin
        case PS is
            when IDLE =>
                write_en_sig <= '0';
                counter_reset_sig <= '1';
                counter_inc_sig <= '0';
                cur_channel_counter_reset_sig <= '1';
                cur_channel_counter_en_sig <= '0';
                end_of_frame_sig <= '1';

                if ( PPM_INPUT = '0' and cur_channel_sig < x"5" ) then
                    NS <= NEW_CHANNEL_PULSE;
                else
                    NS <= IDLE;
                end if;
            
            when NEW_CHANNEL_PULSE =>
                write_en_sig <= '1';
                counter_reset_sig <= '0';
                counter_inc_sig <= '1'; -- start counting cycles for next channel
                cur_channel_counter_reset_sig <= '0';
                cur_channel_counter_en_sig <= '1';
                end_of_frame_sig <= '0';

                if ( PPM_INPUT = '1' ) then
                    NS <= CHANNEL_TRANSMITTING; -- pulse is over but channel is still transmitting
                else
                    NS <= NEW_CHANNEL_PULSE; -- pulse is still going
                end if;

            when CHANNEL_TRANSMITTING =>
                write_en_sig <= '1';
                counter_reset_sig <= '0';
                counter_inc_sig <= '1'; -- keep counting cycles while channel is transmitting

                cur_channel_counter_reset_sig <= '0';
                cur_channel_counter_en_sig <= '1';

                end_of_frame_sig <= '0';

                if ( PPM_INPUT = '0' ) then

                    if ( cur_channel_sig < x"5" ) then
                        NS <= NEW_CHANNEL_PULSE;

                        counter_reset_sig <= '1';
                    else
                        NS <= IDLE;
                    end if;
                else
                    NS <= CHANNEL_TRANSMITTING;
                end if;

            when others =>
                NS <= IDLE; counter_reset_sig <= '1'; write_en_sig <= '0'; counter_inc_sig <= '0';
        end case; 
    end process comb_proc;

    cur_channel_counter_proc: process( CLK, cur_channel_counter_reset_sig )
    begin
        if( cur_channel_counter_reset_sig = '1' ) then
            cur_channel_sig <= (others => '0');
        elsif( rising_edge( CLK ) and cur_channel_counter_en_sig = '1' ) then
            if ( PS = NEW_CHANNEL_PULSE and PrevS = CHANNEL_TRANSMITTING ) then
                cur_channel_sig <= cur_channel_sig + '1';
                -- cur_channel_sig <= std_logic_vector(unsigned( cur_channel_sig ) + 1);
            end if;
        end if;
    end process cur_channel_counter_proc;

    counter_proc: process( CLK, counter_reset_sig )
    begin
        if ( counter_reset_sig = '1' ) then
            channel_count_sig <= (others => '0');
        elsif( rising_edge( CLK ) and counter_inc_sig = '1' ) then
            channel_count_sig <= channel_count_sig + '1';
        end if;
    end process counter_proc;

    with PS select
        Y <=    "00" when IDLE,
                "01" when NEW_CHANNEL_PULSE,
                "10" when CHANNEL_TRANSMITTING;

end behavior;