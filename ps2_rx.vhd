library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity ps2_rx is
   port (
      clock				: in  STD_LOGIC;
      reset				: in  STD_LOGIC;
      ps2data			: in  STD_LOGIC;  -- key clock
      ps2clock			: in  STD_LOGIC;  -- key clock
      rx_en				: in STD_LOGIC;
      rx_done_tick	: out  STD_LOGIC;
      dout				: out STD_LOGIC_VECTOR(7 downto 0)
   );
end ps2_rx;

architecture project_ps2rx of ps2_rx is
   type statetype is (idle, dps, load);
   signal state_reg	: statetype;
   signal state_next	: statetype;
   signal filter_reg	: STD_LOGIC_VECTOR(7 downto 0);
   signal filter_next: STD_LOGIC_VECTOR(7 downto 0);
   signal f_ps2c_reg	: STD_LOGIC;
   signal f_ps2c_next: STD_LOGIC;
   signal b_reg		: STD_LOGIC_VECTOR(10 downto 0);
   signal b_next		: STD_LOGIC_VECTOR(10 downto 0);
   signal n_reg		: unsigned(3 downto 0);
   signal n_next		: unsigned(3 downto 0);
   signal fall_edge	: STD_LOGIC;
	
begin
   --=================================================
   -- filter and falling edge tick generation for ps2clock
   --=================================================
   process (clock, reset)
   begin
      if(reset = '1') then
         filter_reg <= (others => '0');
         f_ps2c_reg <= '0';
      elsif (clock'event and (clock = '1')) then
         filter_reg <= filter_next;
         f_ps2c_reg <= f_ps2c_next;
      end if;
   end process;

   filter_next <= ps2clock & filter_reg(7 downto 1);
   f_ps2c_next <= '1' when filter_reg = "11111111" else
                  '0' when filter_reg = "00000000" else f_ps2c_reg;
   fall_edge <= f_ps2c_reg and (not f_ps2c_next);

   --=================================================
   -- fsmd to extract the 8-bit data
   --=================================================
   -- registers
   process (clock, reset)
   begin
      if(reset = '1') then
         state_reg 	<= idle;
         n_reg 		<= (others => '0');
         b_reg 		<= (others => '0');
      elsif (clock'event and (clock = '1')) then
         state_reg 	<= state_next;
         n_reg 		<= n_next;
         b_reg 		<= b_next;
      end if;
   end process;
	
   -- next-state logic
   process(state_reg, n_reg, b_reg, fall_edge, rx_en, ps2data) begin
      rx_done_tick 	<= '0';
      state_next 		<= state_reg;
      n_next 			<= n_reg;
      b_next 			<= b_reg;
      case state_reg is
         when idle =>
            if fall_edge='1' and rx_en='1' then
               -- shift in start bit
               b_next <= ps2data & b_reg(10 downto 1);
               n_next <= "1001";
               state_next <= dps;
            end if;
         when dps =>  -- 8 data + 1 pairty + 1 stop
            if fall_edge='1' then
            b_next <= ps2data & b_reg(10 downto 1);
               if n_reg = 0 then
                   state_next <=load;
               else
                   n_next <= n_reg - 1;
               end if;
            end if;
         when load =>
            -- 1 extra clock to complete the last shift
            state_next <= idle;
            rx_done_tick <='1';
      end case;
   end process;
   -- output
   dout <= b_reg(8 downto 1); -- data bits
end project_ps2rx;