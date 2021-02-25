library IEEE;

use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity ppm_gen is
    port(
        RESET, CLK, EN : in std_logic;
        REG0: in std_logic_vector( 31 downto 0 );
        REG1: in std_logic_vector( 31 downto 0 );
        REG2: in std_logic_vector( 31 downto 0 );
        REG3: in std_logic_vector( 31 downto 0 );
        REG4: in std_logic_vector( 31 downto 0 );
        REG5: in std_logic_vector( 31 downto 0 );
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
    component down_counter_32bit_6reg is
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
    end component down_counter_32bit_6reg;

----------------------------------------------
--          Signal declarations             --
----------------------------------------------
    type state_type is ( TRANSMITTING_PULSE, CHANNEL_WAIT_IDLE );

    signal PS, NS, PrevS: state_type;

    -- system outputs
    signal cur_channel_sig : std_logic_vector( 3 downto 0 ) := x"0";
    signal ppm_out_sig : std_logic := '1'; -- MP-1 has an active low ppm signal

    -- signals for pulse counter
    signal pulse_count_sig;
    signal pulse_over_sig;
    signal pulse_counter_en_sig : std_logic := '0';

    -- signals for frame counter
    signal frame_count_sig;
    signal frame_over_sig;
    signal frame_reset_sig : std_logic := '0';

    -- signals channel_duration_counter
    signal ch_dur_counter_reset_sig : std_logic := '1';
    signal ch_dur_counter_load_sig : std_logic := '1'; -- can always leave load ON, just use enable
    signal ch_dur_counter_en_sig : std:logic := '0';
    signal ch_dur_over_sig : std_logic;

begin

    pulse_counter: entity pulse_delay_up_counter_wReset_16bit
    PORT MAP(
        clk => CLK,
        reset => RESET,
        enable => pulse_counter_en_sig,
        count => pulse_count_sig,
        count_trigger => pulse_over_sig
    );

    frame_counter: entity frame_up_counter_wReset_24bit
    PORT MAP(
        clk => CLK,
        reset => frame_reset_sig,
        enable => EN,
        count => frame_count_sig,
        count_trigger => frame_over_sig
    );

    channel_duration_counter: entity down_counter_32bit_6reg
    PORT MAP(
        clk => CLK,
        reset => ch_dur_counter_reset_sig,
        load => ch_dur_counter_load_sig,
        count_enable => ch_dur_counter_en_sig,
        reg_sel => cur_channel_sig,
        reg0 => REG0,
        reg1 => REG1,
        reg2 => REG2,
        reg3 => REG3,
        reg4 => REG4,
        reg5 => REG5,
        empty => ch_dur_over_sig
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
            ppm_out_sig <= '1'; -- default to not transmitting (active low)

            -- signals for pulse counter
            pulse_counter_en_sig <= '0';

            -- signals for frame counter
            frame_reset_sig <= '1';

            -- signals channel_duration_counter
            ch_dur_counter_load_sig <= '1';
            ch_dur_counter_en_sig <= '0';
        end if;
    end process reset_proc;

    sync_proc: process( CLK )
    begin
        if ( rising_edge( CLK ) and EN = '1' ) then
            PrevS <= PS;
            PS <= NS;
        end if;
    end process sync_proc;

    comb_proc: process( PS )
    begin
        -- defaults
        ppm_out_sig <= '1';
        -- signals for pulse counter
        pulse_counter_en_sig <= '0';
        -- signals for frame counter
        frame_reset_sig <= '0'; -- frame counter should always be counting
        -- signals for channel_duration_counter
        ch_dur_counter_load_sig <= '1'; -- can always leave load ON, just use enable
        ch_dur_counter_en_sig <= '0';

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