library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity ps2_tx is
   port (
      clock				: in  STD_LOGIC;
      reset				: in  STD_LOGIC;
      din				: in STD_LOGIC_VECTOR(7 downto 0);
      wr_ps2			: STD_LOGIC;
      ps2data			: inout STD_LOGIC;
      ps2clock			: inout STD_LOGIC;
      tx_idle			: out STD_LOGIC;
      tx_done_tick	: out STD_LOGIC
   );
end ps2_tx;

architecture project_ps2tx of ps2_tx is
   type statetype is (idle, rts, start, data, stop);
   signal state_reg: statetype;
   signal state_next: statetype;
   signal filter_reg: STD_LOGIC_VECTOR(7 downto 0);
   signal filter_next: STD_LOGIC_VECTOR(7 downto 0);
   signal f_ps2c_reg: STD_LOGIC;
   signal f_ps2c_next: STD_LOGIC;
   signal fall_edge: STD_LOGIC;
   signal b_reg: STD_LOGIC_VECTOR(8 downto 0);
   signal b_next: STD_LOGIC_VECTOR(8 downto 0);
   signal c_reg,c_next: unsigned(12 downto 0);
   signal n_reg,n_next: unsigned(3 downto 0);
   signal par: STD_LOGIC;
   signal ps2c_out: STD_LOGIC;
   signal ps2d_out: STD_LOGIC;
   signal tri_c: STD_LOGIC;
   signal tri_d: STD_LOGIC;
	
begin
   --=================================================
   -- filter and falling edge tick generation for ps2clock
   --=================================================
   process (clock, reset) begin
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
   fall_edge 	<= f_ps2c_reg and (not f_ps2c_next);

   --=================================================
   -- fsmd
   --=================================================
   -- registers
   process (clock, reset) begin
      if(reset = '1') then
         state_reg 	<= idle;
         c_reg 		<= (others => '0');
         n_reg  		<= (others => '0');
         b_reg 		<= (others => '0');
      elsif (clock'event and (clock = '1')) then
         state_reg 	<= state_next;
         c_reg 		<= c_next;
         n_reg 		<= n_next;
         b_reg 		<= b_next;
      end if;
   end process;
   -- odd parity bit
   par <= not (din(7) xor din(6) xor din(5) xor din(4) xor
               din(3) xor din(2) xor din(1) xor din(0));
   -- next-state logic
   process(state_reg, n_reg, b_reg, c_reg, wr_ps2, din, par, fall_edge) begin
      state_next 		<= state_reg;
      c_next 			<= c_reg;
      n_next 			<= n_reg;
      b_next 			<= b_reg;
      tx_done_tick 	<='0';
      ps2c_out 		<= '1';
      ps2d_out 		<= '1';
      tri_c 			<= '0';
      tri_d 			<= '0';
      tx_idle 			<='0';
      case state_reg is
         when idle =>
            tx_idle <= '1';
            if(wr_ps2 = '1') then
               b_next 		<= par & din;
               c_next 		<= (others => '1'); -- 2^13-1
               state_next 	<= rts;
            end if;
         when rts =>  -- request to send
            ps2c_out <= '0';
            tri_c 	<= '1';
            c_next 	<= c_reg - 1;
            if(c_reg = 0) then
               state_next <= start;
            end if;
         when start => -- assert start bit
            ps2d_out <= '0';
            tri_d <= '1';
            if(fall_edge = '1') then
               n_next 		<= "1000";
               state_next 	<= data;
            end if;
         when data =>  -- 8 data + 1 pairty
            ps2d_out <= b_reg(0);
            tri_d <= '1';
            if(fall_edge = '1') then
               b_next <= '0' & b_reg(8 downto 1);
               if(n_reg = 0) then
                   state_next <= stop;
               else
                   n_next 		<= n_reg - 1;
               end if;
            end if;
         when stop =>  -- assume floating high for ps2data
            if(fall_edge = '1') then
               state_next 		<= idle;
               tx_done_tick 	<='1';
            end if;
      end case;
   end process;
	
   -- tri-state buffers
   ps2clock <= ps2c_out when tri_c = '1' else 'Z';
   ps2data 	<= ps2d_out when tri_d = '1' else 'Z';
	
end project_ps2tx;