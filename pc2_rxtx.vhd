library ieee;
use ieee.std_logic_1164.all;
entity ps2_rxtx is
   port (
      clock				: in STD_LOGIC;
      reset				: in STD_LOGIC;
      wr_ps2			: STD_LOGIC;
      din				: in STD_LOGIC_VECTOR(7 downto 0);
      dout				: out STD_LOGIC_VECTOR(7 downto 0);
      rx_done_tick	: out  STD_LOGIC;
      tx_done_tick	: out STD_LOGIC;
      ps2data			: inout STD_LOGIC;
      ps2clock			: inout STD_LOGIC
   );
end ps2_rxtx;

architecture project_ps2rxtx of ps2_rxtx is

   signal tx_idle: STD_LOGIC;
	
	component ps2_tx is port (
      clock				: in  STD_LOGIC;
      reset				: in  STD_LOGIC;
      din				: in STD_LOGIC_VECTOR(7 downto 0);
      wr_ps2			: STD_LOGIC;
      ps2data			: inout STD_LOGIC;
      ps2clock			: inout STD_LOGIC;
      tx_idle			: out STD_LOGIC;
      tx_done_tick	: out STD_LOGIC
   ); 
	end component;
	
	component ps2_rx is port (
      clock				: in  STD_LOGIC;
      reset				: in  STD_LOGIC;
      ps2data			: in  STD_LOGIC;  -- key data
      ps2clock			: in  STD_LOGIC; -- key clock
      rx_en				: in STD_LOGIC;
      rx_done_tick	: out  STD_LOGIC;
      dout				: out STD_LOGIC_VECTOR(7 downto 0)
   );end component;
	
begin

	tx_unit: ps2_tx port map(clock, reset, din, wr_ps2, ps2data, ps2clock, tx_idle, tx_done_tick);
	rx_unit: ps2_rx port map(clock, reset, ps2data, ps2clock, tx_idle, rx_done_tick, dout);
	
end project_ps2rxtx;