	component sdram_interface is
		port (
			avs_address       : in    std_logic_vector(23 downto 0) := (others => 'X'); -- address
			avs_byteenable_n  : in    std_logic_vector(1 downto 0)  := (others => 'X'); -- byteenable_n
			avs_chipselect    : in    std_logic                     := 'X';             -- chipselect
			avs_writedata     : in    std_logic_vector(15 downto 0) := (others => 'X'); -- writedata
			avs_read_n        : in    std_logic                     := 'X';             -- read_n
			avs_write_n       : in    std_logic                     := 'X';             -- write_n
			avs_readdata      : out   std_logic_vector(15 downto 0);                    -- readdata
			avs_readdatavalid : out   std_logic;                                        -- readdatavalid
			avs_waitrequest   : out   std_logic;                                        -- waitrequest
			clk_clk           : in    std_logic                     := 'X';             -- clk
			mem_pin_addr      : out   std_logic_vector(12 downto 0);                    -- addr
			mem_pin_ba        : out   std_logic_vector(1 downto 0);                     -- ba
			mem_pin_cas_n     : out   std_logic;                                        -- cas_n
			mem_pin_cke       : out   std_logic;                                        -- cke
			mem_pin_cs_n      : out   std_logic;                                        -- cs_n
			mem_pin_dq        : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			mem_pin_dqm       : out   std_logic_vector(1 downto 0);                     -- dqm
			mem_pin_ras_n     : out   std_logic;                                        -- ras_n
			mem_pin_we_n      : out   std_logic;                                        -- we_n
			reset_reset_n     : in    std_logic                     := 'X'              -- reset_n
		);
	end component sdram_interface;

	u0 : component sdram_interface
		port map (
			avs_address       => CONNECTED_TO_avs_address,       --     avs.address
			avs_byteenable_n  => CONNECTED_TO_avs_byteenable_n,  --        .byteenable_n
			avs_chipselect    => CONNECTED_TO_avs_chipselect,    --        .chipselect
			avs_writedata     => CONNECTED_TO_avs_writedata,     --        .writedata
			avs_read_n        => CONNECTED_TO_avs_read_n,        --        .read_n
			avs_write_n       => CONNECTED_TO_avs_write_n,       --        .write_n
			avs_readdata      => CONNECTED_TO_avs_readdata,      --        .readdata
			avs_readdatavalid => CONNECTED_TO_avs_readdatavalid, --        .readdatavalid
			avs_waitrequest   => CONNECTED_TO_avs_waitrequest,   --        .waitrequest
			clk_clk           => CONNECTED_TO_clk_clk,           --     clk.clk
			mem_pin_addr      => CONNECTED_TO_mem_pin_addr,      -- mem_pin.addr
			mem_pin_ba        => CONNECTED_TO_mem_pin_ba,        --        .ba
			mem_pin_cas_n     => CONNECTED_TO_mem_pin_cas_n,     --        .cas_n
			mem_pin_cke       => CONNECTED_TO_mem_pin_cke,       --        .cke
			mem_pin_cs_n      => CONNECTED_TO_mem_pin_cs_n,      --        .cs_n
			mem_pin_dq        => CONNECTED_TO_mem_pin_dq,        --        .dq
			mem_pin_dqm       => CONNECTED_TO_mem_pin_dqm,       --        .dqm
			mem_pin_ras_n     => CONNECTED_TO_mem_pin_ras_n,     --        .ras_n
			mem_pin_we_n      => CONNECTED_TO_mem_pin_we_n,      --        .we_n
			reset_reset_n     => CONNECTED_TO_reset_reset_n      --   reset.reset_n
		);

