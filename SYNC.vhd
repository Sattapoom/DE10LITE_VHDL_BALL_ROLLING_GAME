LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- To understand why the numbers in these codes are ีused please read the information below

-- 800x600, 60 Hz timing values
-- > Pixel clock = 40 MHz

-- > Horizontal (in Pixels)
-- >> Active Video = 800 
-- >> Front Porch = 40
-- >> Sync Pulse = 128
-- >> Back Porch = 88

-- > Vertical (in Lines)
-- >> Active Video = 600 
-- >> Front Porch = 1
-- >> Sync Pulse = 4
-- >> Back Porch = 23

-- or open this website (http://martin.hinner.info/vga/timing.html) and take a look at 800x600, 60Hz format
-- along with reading the comments within this code.
--
ENTITY SYNC IS
	PORT (
		CLK : IN STD_LOGIC;
		HSYNC : OUT STD_LOGIC;
		VSYNC : OUT STD_LOGIC;
		R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		FRAME : OUT INTEGER RANGE 0 TO 59;
		X_REF : OUT INTEGER RANGE 0 TO 800; --Send out to gamelogic for drawing object
		Y_REF : OUT INTEGER RANGE 0 TO 600; --Send out to gamelogic for drawing object
		DRAW_COLOR : IN STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END SYNC;
ARCHITECTURE MAIN OF SYNC IS
	--1056 come from All Horizon clock's tick need before finish 1 line of pixel (800+40+128+88 = 1056)
	--628 come from All Vertical clock's tick need before finish 1 frame (600+1+4+23 = 628)
	
	SIGNAL HPOS : INTEGER RANGE 0 TO 1056 := 0; --For tracking Horizontal timing to make each Front/Back Porch and Sync Pulse 
	SIGNAL VPOS : INTEGER RANGE 0 TO 628 := 0; --For tracking Vertical timing to make each Front/Back Porch and Sync Pulse 
	SIGNAL FRAME_COUNTER : INTEGER RANGE 0 TO 60 := 0; --For tracking which frame of 60 frame is pending and for reset Horizontal and Vertical sync signal

BEGIN
	PROCESS (CLK)--When Clock provide 1 tick in Active Video duration 1 pixel data will send the signal
	BEGIN
		IF (RISING_EDGE(CLK)) THEN

			IF (HPOS >= 0 AND HPOS <= 800 AND VPOS >= 0 AND VPOS <= 600) THEN --If in "Activer video" duration (800,600)
				X_REF <= HPOS; -- Just for send to game logic component to draw object
				Y_REF <= VPOS;
				R <= DRAW_COLOR(11 DOWNTO 8);--send color signal (RED)
				G <= DRAW_COLOR(7 DOWNTO 4);--send color signal (GREEN)
				B <= DRAW_COLOR(3 DOWNTO 0);--send color signal (BLUE)
			ELSE -- If not in "Active video" duration set Colors signal to 0
				R <= (OTHERS => '0');
				G <= (OTHERS => '0');
				B <= (OTHERS => '0');
			END IF;

			IF (HPOS < 1056) THEN -- if not finish 1 line of pixel
				HPOS <= HPOS + 1; -- keep increase HPOS To be a reference source for Horizon signal
			ELSE			
				HPOS <= 0;-- Reset horizontal signal reference
				
				IF (VPOS < 628) THEN -- Check if not finish 1 frame
					VPOS <= VPOS + 1; -- keep increase VPOS To be a reference source for Vertical signal
				ELSE
					VPOS <= 0; --Reset Vertical signal reference
					FRAME_COUNTER <= FRAME_COUNTER + 1; -- increase frame reference
				END IF;
				
			END IF;

			IF (HPOS > 840 AND HPOS <= 968) THEN-- HSYNC 
			--Horizon Sync Pulse need 128 tick at between Front and Back Porch
			--Therefore Sync Pulse must start at "Active video" + "Front Porch"
			-- = 800+40 = 840
			-- And stop at "All horizontal" - "Back Porch" = 1056-88 = 968
				HSYNC <= '0';-- Horizon Sync Pulse
			ELSE
				HSYNC <= '1';
			END IF;

			IF (VPOS > 601 AND VPOS <= 605) THEN--vsync
			--The reason of using 601 and 605 is the same as Horizontal
			--But this's Vertical sync we must calculate from Vertical timming
			--"Active video" + "Front Porch" = 600 + 1 = 601
			--"All horizontal" - "Back Porch" = 628-23 = 605
				VSYNC <= '0'; -- Make Vertical Sync Pulse
			ELSE
				VSYNC <= '1';
			END IF;
		END IF;
	END PROCESS;

	FRAME <= FRAME_COUNTER;

END MAIN;