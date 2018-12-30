library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity mouse is
   port (
      clock				: in  STD_LOGIC;
      reset				: in  STD_LOGIC;
      mouseDoneTick	: out STD_LOGIC;
      xm					: out STD_LOGIC_VECTOR(8 downto 0);
      ym					: out STD_LOGIC_VECTOR(8 downto 0);
      btnm				: out STD_LOGIC_VECTOR(2 downto 0);
      ps2data			: inout STD_LOGIC;
      ps2clock			: inout STD_LOGIC
   );	
end mouse;

architecture project_ps2mouse of mouse is
   constant STRM: STD_LOGIC_VECTOR(7 downto 0) := "11110100";
   -- stream command F4
   type state_type is (init1, init2, init3, pack1, pack2, pack3, done);
   signal state_reg		: state_type;
   signal state_next		: state_type;
   signal rx_data			: STD_LOGIC_VECTOR(7 downto 0);
   signal rx_done_tick	: STD_LOGIC;
   signal tx_done_tick	: STD_LOGIC;
   signal wr_ps2			: STD_LOGIC;
   signal x_reg			: STD_LOGIC_VECTOR(8 downto 0);
   signal y_reg			: STD_LOGIC_VECTOR(8 downto 0);
   signal x_next			: STD_LOGIC_VECTOR(8 downto 0);
   signal y_next			: STD_LOGIC_VECTOR(8 downto 0);
   signal btn_reg			: STD_LOGIC_VECTOR(2 downto 0);
   signal btn_next		: STD_LOGIC_VECTOR(2 downto 0);
	
	component ps2_rxtx is
		port (
			clock				: in STD_LOGIC;
			reset				: in STD_LOGIC;
			wr_ps2			: STD_LOGIC;     -- ps2 baðlandý
			din				: in STD_LOGIC_VECTOR(7 downto 0);     -- gelen vektör
			dout				: out STD_LOGIC_VECTOR(7 downto 0);    -- stream modu vektörü ( tx componentinde F4 veri yolu açýk komutu gönderilcek)
			rx_done_tick	: out  STD_LOGIC;
			tx_done_tick	: out STD_LOGIC;
			ps2data			: inout STD_LOGIC;
			ps2clock			: inout STD_LOGIC
		);
	end component;

begin

   ps2_rxtx_unit: ps2_rxtx port map(
		clock,
		reset,
		wr_ps2,
		STRM,
		rx_data,
		rx_done_tick,
		tx_done_tick,
		ps2data,
		ps2clock
	); --portmap of rxtx  -- baþka bir komponentte rx-txolarak daðýttýk unutma, isimlerden birleþtirdik.

	-- resetleme
   process (clock, reset) begin
      if(reset = '1') then
         state_reg 	<= init1;
         x_reg 		<= (others => '0');
         y_reg 		<= (others => '0');
         btn_reg 		<= (others => '0');
      elsif (clock'event and (clock = '1')) then
         state_reg 	<= state_next;
         x_reg 		<= x_next;
         y_reg 		<= y_next;
         btn_reg 		<= btn_next;
      end if;
   end process;

   process(state_reg, rx_done_tick, tx_done_tick, x_reg, y_reg, btn_reg, rx_data) begin
      wr_ps2 			<= '0';
      mouseDoneTick	<= '0';
      x_next 			<= x_reg;
      y_next 			<= y_reg;
      btn_next 		<= btn_reg;
      state_next 		<= state_reg;
		
      case state_reg is
         when init1 =>
            wr_ps2 <= '1';
            state_next <= init2;
         when init2 => -- gönderim tamamlama
            if(tx_done_tick = '1') then
               state_next <= init3;
            end if;
         when init3 => --paket gönderimi baþlatma
				if(rx_done_tick='1') then
               state_next <= pack1;
            end if;
         when pack1 => -- 1. paket stop datasýný bekleme
            if(rx_done_tick = '1') then
               state_next 	<= pack2;
               y_next(8) 	<= rx_data(5);
               x_next(8) 	<= rx_data(4);
               btn_next 	<= rx_data(2 downto 0);
            end if;
         when pack2 => -- 2. paket stop datasýný bekleme
            if(rx_done_tick = '1') then
               state_next 				<= pack3;
               x_next(7 downto 0) 	<= rx_data;
            end if;
         when pack3 => -- 3. paket stop datasýný bekleme
            if(rx_done_tick = '1') then
               state_next 				<= done;
               y_next(7 downto 0) 	<= rx_data;
            end if;
         when done =>
            mouseDoneTick 	<= '1';  --tamaamlandý biti
            state_next 		<= pack1;
      end case;
   end process;
	
   xm 	<= x_reg;   -- mouse x kordinaatý
   ym 	<= y_reg;   -- mouse y kordinaatý
   btnm 	<= btn_reg;  -- mouse 3 bit click vektörü
	
end project_ps2mouse;