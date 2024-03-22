LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY Game_Logic IS
	GENERIC (
		radius : INTEGER := 30;
		square_width : INTEGER := 100
	);
	PORT (
		VGACLK : IN STD_LOGIC;
		RESTART : IN STD_LOGIC;
		FRAME_COUNTER : IN INTEGER RANGE 0 TO 59;
		X : IN INTEGER RANGE 0 TO 800;
		Y : IN INTEGER RANGE 0 TO 600;
		ACC_X : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --x-axis acceleration data
		ACC_Y : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --y-axis acceleration data
		ACC_Z : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --z-axis acceleration data
		COLOR : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		SSW : IN STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
END Game_Logic;

ARCHITECTURE MAIN OF Game_Logic IS

	SIGNAL FRAME_COUNTER_PREV : INTEGER RANGE 0 TO 59 := 0;
	SIGNAL X_G : INTEGER;
	SIGNAL Y_G : INTEGER;
	SIGNAL BALL_H : INTEGER RANGE -1 TO 800 := 399;-- Ball's center of circle Position
	SIGNAL BALL_V : INTEGER RANGE -1 TO 600 := 299;
	SIGNAL SQ_SHOW : STD_LOGIC_VECTOR(2 DOWNTO 0) := "111";-- Enemy kill reference
	SIGNAL radius_SQ : INTEGER := radius ** 2;-- Pre-Calculate R^2 for drawing circle B'cus we don't need to calculate R^2 every single time ball move
	SIGNAL LOSED : STD_LOGIC := '0'; --Check if game is finish
	SIGNAL SQ_1_X : INTEGER := 0;--1'st enemy position
	SIGNAL SQ_1_Y : INTEGER := 0;
	SIGNAL SQ_2_X : INTEGER := 350;--2'nd enemy position
	SIGNAL SQ_2_Y : INTEGER := 200;
	SIGNAL SQ_3_X : INTEGER := 200;--3'rd enemy position
	SIGNAL SQ_3_Y : INTEGER := 500;
	SIGNAL BALL_SPEED : INTEGER := 50;

	-- Define function for repeatly using code
	-- This one for Checking Is the giving coordination inside square
	FUNCTION Check_coord_in_Square(pos_x : INTEGER; pos_y : INTEGER; SQ_X : INTEGER; SQ_Y : INTEGER; w : INTEGER; r : INTEGER)
		RETURN STD_LOGIC IS
		VARIABLE result : STD_LOGIC;--Declear retuning variable and it's type
	BEGIN
		IF pos_x - r > SQ_X AND pos_x + r < SQ_X + w AND pos_y - r > SQ_Y AND pos_y + r < SQ_Y + w THEN --If inside square area
			result := '1';
		ELSE
			result := '0';
		END IF;
		RETURN result;
	END FUNCTION;

BEGIN
	X_G <= (to_integer(signed(ACC_X))/BALL_SPEED);
	Y_G <= (to_integer(signed(ACC_Y))/BALL_SPEED);

	PROCESS (VGACLK)
	BEGIN
		IF (RISING_EDGE(VGACLK)) THEN
			---///// Making Motion /////---
			FRAME_COUNTER_PREV <= FRAME_COUNTER;
			IF FRAME_COUNTER /= FRAME_COUNTER_PREV THEN

				BALL_H <= BALL_H - X_G;
				BALL_V <= BALL_V + Y_G;
				
				IF SSW = "00" THEN
					BALL_SPEED <= 10;
				ELSIF SSW = "01" THEN
					BALL_SPEED <= 25;
				ELSIF SSW = "10" THEN
					BALL_SPEED <= 50;
				ELSIF SSW = "11" THEN
					BALL_SPEED <= 100;
				END IF;

				IF BALL_V > 600 THEN
					BALL_V <= 0;
				ELSIF BALL_V < 0 THEN
					BALL_V <= 600;
				END IF;
				IF BALL_H > 800 THEN
					BALL_H <= 0;
				ELSIF BALL_H < 0 THEN
					BALL_H <= 800;
				END IF;

				IF SQ_SHOW(1) = '0' AND SQ_SHOW(2) = '0' THEN
					IF BALL_H < SQ_1_X THEN
						SQ_1_X <= SQ_1_X + 1;
					ELSE
						SQ_1_X <= SQ_1_X - 1;
					END IF;

					IF BALL_V < SQ_1_Y THEN
						SQ_1_Y <= SQ_1_Y + 1;
					ELSE
						SQ_1_Y <= SQ_1_Y - 1;
					END IF;

					IF SQ_1_Y + square_width > 600 THEN
						SQ_1_Y <= 600 - square_width;
					ELSIF SQ_1_Y < 0 THEN
						SQ_1_Y <= 0;
					END IF;
					IF SQ_1_X + square_width > 800 THEN
						SQ_1_X <= 800 - square_width;
					ELSIF SQ_1_X < 0 THEN
						SQ_1_X <= 0;
					END IF;
				ELSE
					IF BALL_H < SQ_1_X + square_width/2 THEN
						SQ_1_X <= SQ_1_X - 2;
					ELSE
						SQ_1_X <= SQ_1_X + 2;
					END IF;

					IF BALL_V < SQ_1_Y + square_width/2 THEN
						SQ_1_Y <= SQ_1_Y - 2;
					ELSE
						SQ_1_Y <= SQ_1_Y + 2;
					END IF;

					IF SQ_1_Y + square_width > 600 THEN
						SQ_1_Y <= 0;
					ELSIF SQ_1_Y < 0 THEN
						SQ_1_Y <= 600;
					END IF;
					IF SQ_1_X + square_width > 800 THEN
						SQ_1_X <= 0;
					ELSIF SQ_1_X < 0 THEN
						SQ_1_X <= 800;
					END IF;
				END IF;

				IF BALL_H < SQ_2_X THEN
					SQ_2_X <= SQ_2_X + 1;
				ELSE
					SQ_2_X <= SQ_2_X - 1;
				END IF;

				IF BALL_V < SQ_2_Y THEN
					SQ_2_Y <= SQ_2_Y + 1;
				ELSE
					SQ_2_Y <= SQ_2_Y - 1;
				END IF;

				IF SQ_2_Y + square_width > 600 THEN
					SQ_2_Y <= 600 - square_width;
				ELSIF SQ_2_Y < 0 THEN
					SQ_2_Y <= 0;
				END IF;
				IF SQ_2_X + square_width > 800 THEN
					SQ_2_X <= 800 - square_width;
				ELSIF SQ_2_X < 0 THEN
					SQ_2_X <= 0;
				END IF;

				IF BALL_H < SQ_3_X THEN
					SQ_3_X <= SQ_3_X + 1;
				ELSE
					SQ_3_X <= SQ_3_X - 1;
				END IF;

				IF BALL_V < SQ_3_Y THEN
					SQ_3_Y <= SQ_3_Y + 1;
				ELSE
					SQ_3_Y <= SQ_3_Y - 1;
				END IF;

				IF SQ_3_Y + square_width > 600 THEN
					SQ_3_Y <= 600 - square_width;
				ELSIF SQ_3_Y < 0 THEN
					SQ_3_Y <= 0;
				END IF;
				IF SQ_3_X + square_width > 800 THEN
					SQ_3_X <= 800 - square_width;
				ELSIF SQ_3_X < 0 THEN
					SQ_3_X <= 0;
				END IF;
			END IF;
			
			---///// Drawing /////---
			IF (SQ_SHOW = "000" OR LOSED = '1') THEN --Checking Is Game is finish? (All enemy is killed "Or" You lose)
				IF RESTART = '0' THEN --if restart button is pushed then restart the game by reset all variable's value
				
					BALL_H <= 399;
					BALL_V <= 299;
					SQ_1_X <= 0;
					SQ_1_Y <= 0;
					SQ_2_X <= 350;
					SQ_2_Y <= 200;
					SQ_3_X <= 200;
					SQ_3_Y <= 500;
					SQ_SHOW <= "111";
					LOSED <= '0';
					
				END IF;
				-- Drawing words is made by calculating linear equations and using them as conditions.
				-- But the Y value of the coordination will be made negative.
				-- This is because a higher Y value means a lower point on the screen.
				
				--- Draw " W I N " ---
				IF LOSED = '0' THEN -- If Not lose
					IF (X > 40 AND X < 60 AND Y > 200 AND Y < 400) OR (X > 240 AND X < 260 AND Y > 200 AND Y < 400) OR (-Y < X - 440 AND -Y > X - 460 AND Y > 300 AND Y < 400) OR (-Y <- X - 140 AND -Y >- X - 160 AND Y > 300 AND Y < 400) THEN
						COLOR <= x"FFF";-- W
					ELSIF (X > 390 AND X < 410 AND Y > 200 AND Y < 400) OR (X > 300 AND X < 500 AND ((Y > 200 AND Y < 220) OR (Y > 380 AND Y < 400))) THEN
						COLOR <= x"FFF";-- I
					ELSIF (X > 540 AND X < 560 AND Y > 200 AND Y < 400) OR (X > 740 AND X < 760 AND Y > 200 AND Y < 400) OR (-Y <- X + 360 AND -Y >- X + 340 AND Y > 200 AND Y < 400) THEN
						COLOR <= x"FFF";-- N
					ELSE
						COLOR <= x"485"; -- Other parts besides "W I N" (background) are Bright Green
					END IF;
				ELSE
				-- Draw "GAME OVER"
					IF (( (X-200)**2  +  (Y-200)**2 ) ) <= 2500 AND (( (X-200)**2  +  (Y-200)**2 ) ) >= 1600 AND X<=220 THEN
						COLOR <= x"FFF"; --G
					ELSIF (( X >=210 AND X<=220) AND ( Y > 200 AND Y <240)) OR ((((X > 200 AND X<220) OR (X > 250 AND X<305)) AND Y>200 AND Y<210)) THEN
						COLOR <= x"FFF"; --G
					ELSIF (((( -2*(x - 350) ) < Y) AND (( -2*(x - 360) ) > Y)) OR ((( 2*(x - 210) ) < Y) AND (( 2*(x - 200) ) > Y))) AND Y >= 150 AND Y <=250 THEN
						COLOR <= x"FFF"; --A
					ELSIF (((-3*(X-420)) <= Y AND (-3*(X-430)) >= Y) OR ((3*(X-365)) <= Y AND (3*(X-355)) >= Y) OR ((((4*(X-350)) <= Y AND (4*(X-340)) >= Y) OR ((-4*(X-435)) <= Y AND (-4*(X-445) >= Y))) AND Y <= 180) ) AND Y >= 150 AND Y <=250 THEN
						COLOR <= x"FFF"; --M
					ELSIF X> 450 AND X<460 AND Y >= 150 AND Y <=250 THEN
						COLOR <= x"FFF"; --E
					ELSIF (X>= 460 AND X<530) AND ((Y >= 150 AND Y <=160) OR (Y >= 195 AND Y <=205) OR (Y >= 240 AND Y <=250)) THEN
						COLOR <= x"FFF"; --E
					ELSIF (( (X-200)**2  +  (Y-320)**2 ) ) <= 2500 AND (( (X-200)**2  +  (Y-320)**2 ) ) >= 1600 THEN
						COLOR <= x"FFF"; --O
					ELSIF (((3*(X-150) > Y) AND (3*(X-160) < Y)) OR ((-3*(X-400) < Y) AND (-3*(X-410) > Y))) AND Y >= 270 AND Y <=370  THEN
						COLOR <= x"FFF"; --V
					ELSIF (X >= 330 AND X <=340 AND Y >= 270 AND Y <=370) OR ((X>= 340 AND X<440) AND ((Y >= 270 AND Y <=280) OR (Y >= 315 AND Y <=325) OR (Y >= 360 AND Y <=370))) THEN
						COLOR <= x"FFF"; --E2
					ELSIF ((X>440 AND X<450))AND Y >= 270 AND Y <=370 THEN
						COLOR <= x"FFF";
					ELSIF ((X>520 AND X<530))AND Y >= 270 AND Y <=320 THEN
						COLOR <= x"FFF";
					ELSIF ((X>440 AND X<530)) AND ((Y>= 270 AND Y<= 280) OR (Y>= 320 AND Y<= 330)) THEN
						COLOR <= x"FFF";
					ELSIF (3*(X-405)) <= Y AND (3*(X-395)) >= Y AND Y >320 AND Y<370 THEN
						COLOR <= x"FFF"; --R
					ELSE
						COLOR <= x"955"; -- Other parts besides "GAME OVER" (background) are Faded Red
					END IF;
				END IF;
				
			-- Other else If game is not finished yet Draw objects
			
			ELSIF ((X - (BALL_H)) ** 2 + (Y - (BALL_V)) ** 2 <= radius_SQ) THEN -- Drawing a ball
				--by Circle formular (x-h)^2 + (y-k)^2 = R^2
				-- But we use "<=" R^2 instead of "=" R^2 Just for full fill the circle
				COLOR <= x"B7F";
				
			--Check Is the Drawing pixel is at the square area
			ELSIF Check_coord_in_Square(X, Y, SQ_1_X, SQ_1_Y, square_width, 0) = '1' AND SQ_SHOW(0) = '1' THEN --If 1'st enemy (red enemy) is not killed
				
				IF SQ_SHOW(1) = '0' AND SQ_SHOW(2) = '0' THEN -- Check Is 2'nd and 3'rd enemy is killed
					COLOR <= x"485";-- last alive enemy become green
					
				ELSE -- If other Enemy not killed Make this enemy Red
					IF FRAME_COUNTER < 30 THEN -- For blinking square every 30 frame (0.5 sec)
						COLOR <= x"A55";-- Faded red 
					ELSE
						COLOR <= x"C55";-- Brighten red
					END IF;
				END IF;
				
			ELSIF Check_coord_in_Square(X, Y, SQ_2_X, SQ_2_Y, square_width, 0) = '1' AND SQ_SHOW(1) = '1' THEN -- IF 2'nd enemy is not kill draw it
				COLOR <= x"485"; -- Green
			ELSIF Check_coord_in_Square(X, Y, SQ_3_X, SQ_3_Y, square_width, 0) = '1' AND SQ_SHOW(2) = '1' THEN -- IF 3'rd enemy is not kill draw it
				COLOR <= x"485"; -- Green
			ELSE
				COLOR <= x"FFF"; -- Other parts besides The Ball and 3 Enemy (Backgrond) is white
			END IF;
			
			---///// Enemy killing And Game ending /////---
			IF Check_coord_in_Square(BALL_H, BALL_V, SQ_1_X, SQ_1_Y, square_width, radius) = '1' AND SQ_SHOW(0) = '1' THEN -- If The ball inside last enemy
				IF SQ_SHOW(1) = '0' AND SQ_SHOW(2) = '0' THEN -- And if other enemy is killed
					SQ_SHOW(0) <= '0'; --Kill the last enemy by set SQ_SHOW(0) to 0
				ELSE
					LOSED <= '1';-- End the game (LOSED) even if other enemy is killed or not
				END IF;
			ELSIF Check_coord_in_Square(BALL_H, BALL_V, SQ_2_X, SQ_2_Y, square_width, radius) = '1' AND SQ_SHOW(1) = '1' THEN -- If ball inside 2'nd square
				SQ_SHOW(1) <= '0';-- kill 2'nd enemy
			ELSIF Check_coord_in_Square(BALL_H, BALL_V, SQ_3_X, SQ_3_Y, square_width, radius) = '1' AND SQ_SHOW(2) = '1' THEN-- If ball inside 3'rd square
				SQ_SHOW(2) <= '0';--kill 3'rd enemy
			END IF;
		END IF;
	END PROCESS;
END MAIN;