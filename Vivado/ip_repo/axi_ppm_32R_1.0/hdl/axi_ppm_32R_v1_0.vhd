library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_ppm_32R_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 7
	);
	port (
		-- Users to add ports here
        PPM_IN : in std_logic; -- PPM input from RC transmitter
		PPM_IN_2 : in std_logic; -- PPM input from emulated transmitter (arduino)
        PPM_out : out std_logic;
        PPM_CAP_CUR_STATE : out std_logic_vector( 1 downto 0 );
        PPM_CAP_WRITE_EN : out std_logic;
		PPM_CAP_CUR_CH : out std_logic_vector( 2 downto 0 );
		
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axi_ppm_32R_v1_0;

architecture arch_imp of axi_ppm_32R_v1_0 is

	-- component declaration
	component axi_ppm_32R_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 7
		);
		port (
		PPM_IN : in std_logic;
		PPM_OUT : out std_logic;
		PPM_INPUT_SELECT : out std_logic;
		PPM_CAP_WEN : in std_logic;
		PPM_CAP_WADDR : in std_logic_vector( 2 downto 0 );
		PPM_CAP_RESET : in std_logic;
		PPM_CAP_WDATA : in std_logic_vector( C_S_AXI_DATA_WIDTH-1 downto 0 );
		PPM_CAP_END_OF_FRAME : in std_logic;
		RELAY_MODE : out std_logic;
		PPM_GEN_REG0 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		PPM_GEN_REG1 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		PPM_GEN_REG2 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		PPM_GEN_REG3 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		PPM_GEN_REG4 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		PPM_GEN_REG5 : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		PPM_CAP_RST : out std_logic;
		PPM_GEN_RST : out std_logic;
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component axi_ppm_32R_v1_0_S00_AXI;
	
	-- USER COMPONENTS
    component ppm_cap is
    port (  
        CLK, RESET, EN : in std_logic;
        PPM_INPUT : in std_logic;
        CHANNEL_COUNT : out std_logic_vector( 31 downto 0 );
        CHANNEL : out std_logic_vector( 2 downto 0 );
        WRITE_EN : out std_logic;
        END_OF_FRAME : out std_logic;
        Y : out std_logic_vector( 1 downto 0) );
    end component;
	
	-- PPM_CAP signals
	signal ppm_input_select_s : std_logic := '0';
	signal ppm_input_s : std_logic := '0';
    signal ppm_cap_reset_s : std_logic;
    signal ppm_cap_rst_reg : std_logic;
    signal ppm_cap_en_s : std_logic := '1';
    signal ppm_cap_channel_cycle_count_s : std_logic_vector( 31 downto 0 );
    signal ppm_cap_cur_channel_s : std_logic_vector( 2 downto 0 );
    signal ppm_cap_write_en_s : std_logic;
    signal ppm_cap_end_of_frame_s : std_logic;
    signal ppm_cap_cur_state_s : std_logic_vector( 1 downto 0 );
    
	-- PPM_GEN signals
    signal relay_mode_s : std_logic;
	signal sw_PPM_OUT_s : std_logic; -- this signal holds the output of the PPM_GEN module

	signal ppm_gen_reset_s : std_logic;
	signal ppm_gen_en_s : std_logic;
    signal ppm_gen_rst_reg : std_logic;
	
	signal reg0_gen : std_logic_vector(32-1 downto 0);
	signal reg1_gen : std_logic_vector(32-1 downto 0);
	signal reg2_gen : std_logic_vector(32-1 downto 0);
	signal reg3_gen : std_logic_vector(32-1 downto 0);
	signal reg4_gen : std_logic_vector(32-1 downto 0);
	signal reg5_gen : std_logic_vector(32-1 downto 0);
	
	component ppm_gen_6chnl is
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
	end component;
	
begin
    
-- Instantiation of Axi Bus Interface S00_AXI
axi_ppm_32R_v1_0_S00_AXI_inst : axi_ppm_32R_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    PPM_IN => PPM_IN,
	    PPM_OUT => PPM_OUT,
		PPM_INPUT_SELECT => ppm_input_select_s,
	    PPM_CAP_WEN => ppm_cap_write_en_s,
		PPM_CAP_WADDR => ppm_cap_cur_channel_s,
		PPM_CAP_RESET => ppm_cap_reset_s,
		PPM_CAP_WDATA => ppm_cap_channel_cycle_count_s,
		PPM_CAP_END_OF_FRAME => ppm_cap_end_of_frame_s,
		RELAY_MODE => relay_mode_s,
		PPM_GEN_REG0 => reg0_gen,
		PPM_GEN_REG1 => reg1_gen,
		PPM_GEN_REG2 => reg2_gen,
		PPM_GEN_REG3 => reg3_gen,
		PPM_GEN_REG4 => reg4_gen,
		PPM_GEN_REG5 => reg5_gen,
		PPM_CAP_RST => ppm_cap_rst_reg,
		PPM_GEN_RST => ppm_gen_rst_reg,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
--        S_AXI_WSTRB => axi_wstrb_sig,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

	----------------------------------------------------
	-- USER COMPONENTS ---------------------------------
	----------------------------------------------------
	ppm_input_s <= PPM_IN when ( ppm_input_select_s = '0' ) else PPM_IN_2;
    PPM_CAP_WRITE_EN <= ppm_cap_write_en_s;
    ppm_cap_en_s <= '1';
    PPM_CAP_CUR_STATE <= ppm_cap_cur_state_s;
	PPM_CAP_CUR_CH <= ppm_cap_cur_channel_s;

    ppm_cap_reset_s <= ( NOT s00_axi_aresetn ) OR ( ppm_cap_rst_reg );
	-- DEFINE USER COMPONENTS
	ppm_capture: ppm_cap
    port map(
        CLK => s00_axi_aclk,
        RESET => ppm_cap_reset_s,--ppm_cap_reset_s,
        EN => ppm_cap_en_s,
        PPM_INPUT => ppm_input_s,
        CHANNEL_COUNT => ppm_cap_channel_cycle_count_s,
        CHANNEL => ppm_cap_cur_channel_s,
        WRITE_EN => ppm_cap_write_en_s,
        END_OF_FRAME => ppm_cap_end_of_frame_s,
        Y => ppm_cap_cur_state_s
    );
    
--    PPM_OUT <= PPM_IN when relay_mode_s = '1' else sw_PPM_OUT_s;
	hw_relay_proc: process( s00_axi_aclk ) is
	begin
		if( rising_edge( s00_axi_aclk ) ) then
			if ( relay_mode_s = '0' ) then
				ppm_gen_en_s <= '0';
				PPM_OUT <= ppm_input_s;
			else
				ppm_gen_en_s <= '1';
				PPM_OUT <= sw_PPM_OUT_s;
            end if;
        end if;
    end process hw_relay_proc;

    ppm_gen_reset_s <= ( NOT s00_axi_aresetn ) OR ( ppm_gen_rst_reg );
    --PPM Generator
    ppm_gen : ppm_gen_6chnl
	port map(
        clk => s00_axi_aclk,
        reset => ppm_gen_reset_s,
        enable => ppm_gen_en_s,
        reg_0 => reg0_gen,
        reg_1 => reg1_gen,
        reg_2 => reg2_gen,
        reg_3 => reg3_gen,
        reg_4 => reg4_gen,
        reg_5 => reg5_gen,
        ppm_out => sw_PPM_OUT_s);

	-- User logic ends

end arch_imp;
