----------------------------------------------------------------------------------
-- VGA test in class
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA640 is port
	(
		clock   	: in  STD_LOGIC;
		HS 		: out STD_LOGIC;
		VS			: out STD_LOGIC;
		x     	: out integer;
		y     	: out integer; 
		valid 	: out STD_LOGIC
	);
end VGA640;

architecture project_VGA of VGA640 is
	signal HSx				: STD_LOGIC;
	signal xCoordinate	: integer;
	signal yCoordinate	: integer;
	signal hvalid			: STD_LOGIC;
	signal vvalid			: STD_LOGIC;
	constant TSH 			: integer := 800;
	constant TDISPH 		: integer := 640;
begin
	
	valid <= hvalid and vvalid;
	x 		<= xCoordinate; 
	y 		<= yCoordinate; 
	HS 	<= HSx;
	 
	process(clock, xCoordinate) is begin
		if(RISING_EDGE(clock)) then
			if(xCoordinate = (TSH - 1)) then 
				xCoordinate <= 0;
			else 
				xCoordinate <= xCoordinate + 1; 
			end if;
			
			if(xCoordinate = 0) then 
				hvalid <= '1'; 
			end if;
			
			if(xCoordinate = (TDISPH - 1)) then
				hvalid <= '0'; 
			end if;
			
			if(xCoordinate = 655) then 
				HSx <= '0'; 
			end if;
			
			if(xCoordinate = 751) then 
				HSx <= '1'; 
			end if;
		end if;
	end process;
	
	process(HSx, yCoordinate) is begin
		if(RISING_EDGE(HSx)) then
			if(yCoordinate = 520) then 
				yCoordinate <= 0;
			else 
				yCoordinate <= yCoordinate + 1; 
			end if;
			
			if(yCoordinate = 0) then 
				vvalid <= '1';
			end if;
			
			if(yCoordinate = 479) then 
				vvalid <= '0'; 
			end if;
			
			if(yCoordinate = 489) then 
				VS <= '0'; 
			end if;
			
			if(yCoordinate = 491) then 
				VS <= '1'; 
			end if;
			
		end if;
	end process;
end project_VGA;

