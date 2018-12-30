-- PS2 Mouse on VGA screen
--
-- Hasan Eren KESKIN - 151220144053
-- Ismet Baran Oncul - 151220144063
-- Muge Altingeyik	- 151220144004

-- Date: 25.12.2018
-- v0.1


library 	IEEE;
use 		IEEE.STD_LOGIC_1164.ALL;
use 		IEEE.NUMERIC_STD.ALL;
use 		IEEE.STD_LOGIC_UNSIGNED.ALL;

-- PS2 and VGA entity
entity ps2mouseOnVGA is
	port (
		clock		: in  STD_LOGIC; 
		reset		: in  STD_LOGIC;		
		ps2data	: inout STD_LOGIC;
		ps2clock	: inout STD_LOGIC;
		hsync		: out  STD_LOGIC;
		vsync		: out  STD_LOGIC;
		led		: out STD_LOGIC_VECTOR(7 downto 0);
		RGB		: out  STD_LOGIC_VECTOR (2 downto 0)
	);
end ps2mouseOnVGA;

architecture project_ps2mouseOnVGA of ps2mouseOnVGA is
		
	-- VGA Component from vgainterface
	component VGA640 is 
		port (
			clock   	: in  STD_LOGIC;
			HS 		: out STD_LOGIC;
			VS			: out STD_LOGIC;
			x     	: out integer;
			y     	: out integer; 
			valid 	: out STD_LOGIC
		); 
	end component;
	
	-- PS2 Mouse component from mouse_unit 
	component mouse is 
		port (
			clock			: in  STD_LOGIC;
			reset			: in  STD_LOGIC;
			ps2data		: inout STD_LOGIC;
			ps2clock		: inout STD_LOGIC;
			xm				: out STD_LOGIC_VECTOR(8 downto 0);
			ym				: out STD_LOGIC_VECTOR(8 downto 0);
			btnm			: out STD_LOGIC_VECTOR(2 downto 0);
			mouseDoneTick	: out STD_LOGIC
		);
	end component;
	 
	-- Signal and type definetions
	type PREVIOUS_POSITION is array (50 downto 0) of unsigned(9 downto 0);
	signal previousRectangleXcoordinate : PREVIOUS_POSITION;
	signal previousRectangleYcoordinate : PREVIOUS_POSITION;
	signal xRegister			: unsigned(9 downto 0);
	signal xNext				: unsigned(9 downto 0);
	signal yRegister			: unsigned(9 downto 0);
	signal yNext				: unsigned(9 downto 0);
	signal rawXdata			: unsigned(9 downto 0);
	signal rawYdata			: unsigned(9 downto 0);
	signal clickXposition	: unsigned(9 downto 0);
	signal clickYposition	: unsigned(9 downto 0);
	signal xm 					: STD_LOGIC_VECTOR(8 downto 0);
	signal ym					: STD_LOGIC_VECTOR(8 downto 0);
	signal button				: STD_LOGIC_VECTOR(2 downto 0);
	signal mouseDoneTick		: STD_LOGIC := '0';
	signal clock1				: STD_LOGIC := '0';
	signal valid				: STD_LOGIC := '0';
	signal xCoordinations	: integer range 0 to 800;
	signal yCoordinations 	: integer range 0 to 640;
	signal i						: integer range 0 to 50 := 0;
	signal counter				: integer;
	signal buyutec				: integer;
	signal buyutec_prev		: integer;
	signal bastim_sinyali	: STD_LOGIC := '0';

	
begin

	-- VGA portmap
	vgainterface : vga640 port map(
		clock1,
		hsync,
		vsync,
		xCoordinations,
		yCoordinations,
		valid
	);  
	
	-- PS2 Mouse portmap
	mouse_unit  : mouse port map(
		clock,
		reset,
		ps2data,
		ps2clock,
		xm,
		ym,
		button,
		mouseDoneTick
	); 
	
	-- Reset Process for registers
   process(clock, reset) begin
      if(reset = '1') then
         xRegister <= (others => '0');	
			yRegister <= (others => '0');
      elsif (clock'event and (clock = '1')) then
         xRegister <= xNext;   
			yRegister <= yNext;
      end if;
   end process;
	
	-- Overflow Blocking
	rawXdata <= xRegister + unsigned(xm(8) & xm);
	rawYdata <= yRegister - unsigned(ym(8) & ym);
	
   xNext <= xRegister when (mouseDoneTick = '0') else
			"0000000000" when (rawXdata(9 downto 5) = "11111") else
			"1001111111" when (rawXdata(9 downto 5) = "10100") else rawXdata;
	
	yNext <= yRegister when (mouseDoneTick = '0') else
			"0000000000" when (rawYdata(9 downto 5) = "11111") else 
			"0111011111" when (rawYdata(9 downto 5) = "01111") else rawYdata;
			
-- Control Process
process(clock, i) is begin

	if(RISING_EDGE(clock)) then
		clock1 <= not clock1;
		
		-- PS2 Mouse Button Control
		--- button(0) = left click
		--- button(1) = right click
		--- button(2) = wheel click
		if((mouseDoneTick = '1') and (button(0) = '1')) then
			buyutec 			<= 0;
			bastim_sinyali <= not(bastim_sinyali);
			clickXposition <= xNext;
			clickYposition <= yNext;
			led 				<= "11111111";
			previousRectangleXcoordinate(i) <= clickXposition;
			previousRectangleYcoordinate(i) <= clickYposition;   
			i 		<= i + 1;
		elsif(button(0) = '0') then 
			led 	<= "00000000";
		end if;
		
		-- If click second time, set rectangle size on last size
		if(bastim_sinyali /= '1') then
			buyutec <= buyutec_prev;
		end if;
		
		-- Rectangle enlarging with animation
		if(counter = 3000000) then
			if(buyutec < 100) then
				buyutec <= buyutec + 1;
			else 
				buyutec <= 100;
			end if;
			buyutec_prev <= buyutec;
			if(buyutec_prev = 100) then 
				buyutec_prev <= 0;
			end if;
			counter <= 0;
		else
			counter <= counter + 1;
		end if;

		-- Rectangle size and color settings
		if(xCoordinations < 640) and (yCoordinations < 480) then
		
			-- Set cursor shape as rectangle with x size 5, y size 2
			if((xCoordinations < (xNext + 5)) and (xCoordinations > (xNext - 2)) and (yCoordinations < (yNext + 5)) and (yCoordinations > (yNext - 2))) then
				RGB <= "100";	-- color: red
				
			-- Rectangle size after click
			elsif((xCoordinations < (clickXposition + buyutec)) and (xCoordinations > (clickXposition - buyutec))) and ((yCoordinations < (clickYposition + buyutec)) and (yCoordinations > (clickYposition - buyutec)))then
				RGB <= not(valid) & '0' & valid;	-- color: blue;
			else
				RGB <= "011";	-- color: cyan
			end if;
		else
			RGB <= "000";	-- color: black	
		end if;	    
	end if;
end process;   
 
end project_ps2mouseOnVGA;