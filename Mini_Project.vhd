--==============================================================================
-- This is a part of The High Level Design for Digital Systems course.(010123225 - 1/2023) KMUTNB
-- นี่เป็นส่วนหนึ่งของรายวิชา High Level Design for Digital Systems (010123225 - 1/2566) มหาวิทยาลัยพระจอมเกล้าพระนครเหนือ
-- 
-- Prepared and published by
-- 1.Sattapoom Tulyasuk ID:6301012630192
-- 2.THANASAK MEKARUTTANAKUL ID:6301012620049
--
-- จัดทำและเผยแพร่โดย
-- 1.นายเสฏฐภูมิ ตุลยสุข รหัส 6301012630192
-- 2.นายธนะศักดิ์ เมฆารัตนกุล รหัส 6301012620049
--
-- Supervisor
-- Asst.Prof.Dr.Danucha Prasertsom
--
-- อาจารย์ที่ปรึกษา
-- อ.ดร.ดนุชา ประเสริฐสม
--------------------------------------------------------------------------------
--
--	How to play
-- 1. Close the rightest slide switch.
-- 2. Roll the ball by tilting the FPGA board.
-- 3. Do not hit the red box, otherwise the game will be considered ends and you will lose.
-- 4. Roll the ball to collect all the green boxes to win the game.
-- 5. When the game ends, you can press Push button KEY 0 to start the game.
--
--
--	วิธีเล่น
--	1.ปิด Slide switch ตัวขวาสุด
--	2.กลิ้งลูกบอลด้วยการเอียงบอร์ด FPGA
--	3.ห้ามโดนกล่องสีแดงไม่เช่นนั้นจะถือว่าจบเกมและแพ้
--	4.กลิ้งลูกบอลไปเก็บกล่องสีเขียวให้หมดทุกกล่องเพื่อชนะเกม
--	5.เมื่อจบเกมสามารถกดปุ่ม Push button KEY 0 เพิ่อเริ่มเกมใหม่อีกครั้ง
--    
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY Mini_Project IS
	PORT (
		CLOCK_50 : IN STD_LOGIC; --Input from Clock of DE10-Lite (50MHz)
		VGA_HS, VGA_VS : OUT STD_LOGIC; --Output to Horizon/Vertical sync signal of VGA pin/line
		VGA_R, VGA_B, VGA_G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);--Output to Red/Green/Blue signal of VGA pin/line
		RESTART : IN STD_LOGIC;-- Input from restart button
		RESET : IN STD_LOGIC; -- Input from reset button
		miso : IN STD_LOGIC; --SPI bus: master in, slave out
		sclk : BUFFER STD_LOGIC; --SPI bus: serial clock
		ss_n : BUFFER STD_LOGIC_VECTOR(0 DOWNTO 0); --SPI bus: slave select
		mosi : OUT STD_LOGIC; --SPI bus: master out, slave in
		SSW : IN STD_LOGIC_VECTOR(1 DOWNTO 0) --slide switch input for Change ball speed
	);
END Mini_Project;
ARCHITECTURE MAIN OF Mini_Project IS
	SIGNAL VGACLK : STD_LOGIC;
	SIGNAL FRAME_COUNTER : INTEGER RANGE 0 TO 59 := 0; --Frame tracking for animation(1 to 60 frames)
	SIGNAL X : INTEGER RANGE 0 TO 800; --Horizontal pixel position of VGA being rendered
	SIGNAL Y : INTEGER RANGE 0 TO 600; --Vertical pixel position of VGA being rendered
	SIGNAL COLOR : STD_LOGIC_VECTOR(11 DOWNTO 0) := x"FFF";
	SIGNAL ACC_X : STD_LOGIC_VECTOR(15 DOWNTO 0); --x-axis acceleration data
	SIGNAL ACC_Y : STD_LOGIC_VECTOR(15 DOWNTO 0); --y-axis acceleration data
	SIGNAL ACC_Z : STD_LOGIC_VECTOR(15 DOWNTO 0); --z-axis acceleration data (Not in use.)

	COMPONENT SYNC IS
		PORT (
		-- We are going to render on 800x600/ 60Hz format. Then we need 40MHZ for VGA's clock.
		--For Horizon/Vertical sync Pulse.Please Check the detail on http://martin.hinner.info/vga/timing.html)
			CLK : IN STD_LOGIC; --VGA clock (40MHZ needed for this format)
			HSYNC : OUT STD_LOGIC; --Horizon sync
			VSYNC : OUT STD_LOGIC; --Vertical sync
			R : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); --(RED) Pixel's color signal
			G : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); --(GREEN) Pixel's color signal
			B : OUT STD_LOGIC_VECTOR(3 DOWNTO 0); --(BLUE) Pixel's color signal
			FRAME : OUT INTEGER RANGE 0 TO 59; --VGA Rendered Frame at the moment (60 FPS)
			X_REF : OUT INTEGER RANGE 0 TO 800; --Horizontal pixel position of VGA being rendered (to calculate and draw object at correct position)
			Y_REF : OUT INTEGER RANGE 0 TO 600; --Vertical pixel position of VGA being rendered (to calculate and draw object at correct position)
			DRAW_COLOR : IN STD_LOGIC_VECTOR(11 DOWNTO 0)
		);
	END COMPONENT SYNC;

	COMPONENT vga_clk_40 IS
		--This is Clock scaler (50MHz to 40 MHz) made from Quartus prime tools.(IP catalog => Library => Basic Functions => Clock)
		PORT (
			inclk0 : IN STD_LOGIC := 'X';
			c0 : OUT STD_LOGIC
		);
	END COMPONENT vga_clk_40;

	COMPONENT pmod_accelerometer_adxl345 IS
	-- This component is adapted from Scott_1767's component. (Scott_1767 is DigiKey Employee The TechForum writer.)
	-- Visit his forum https://forum.digikey.com/t/accelerometer-adxl345-pmod-controller-vhdl/12921
	-- This component is used to read the acceleration value from ADXl345 using SPI communication.
		GENERIC (
			clk_freq : INTEGER := 50; --system clock frequency in MHz
			data_rate : STD_LOGIC_VECTOR := "1101"; --data rate code to configure the accelerometer
			data_range : STD_LOGIC_VECTOR := "11"
		); --data range code to configure the accelerometer
		PORT (
			clk : IN STD_LOGIC; --system clock
			reset_n : IN STD_LOGIC; --active low asynchronous reset
			miso : IN STD_LOGIC; --SPI bus: master in, slave out
			sclk : BUFFER STD_LOGIC; --SPI bus: serial clock
			ss_n : BUFFER STD_LOGIC_VECTOR(0 DOWNTO 0); --SPI bus: slave select
			mosi : OUT STD_LOGIC; --SPI bus: master out, slave in
			acceleration_x : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); --x-axis acceleration data
			acceleration_y : OUT STD_LOGIC_VECTOR(15 DOWNTO 0); --y-axis acceleration data
			acceleration_z : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
		); --z-axis acceleration data (Not in use)
	END COMPONENT;

	COMPONENT Game_Logic IS
		GENERIC (
			radius : INTEGER := 30; --size of the ball
			square_width : INTEGER := 100 --size of enemies (squares)
		);
		PORT (
			VGACLK : IN STD_LOGIC;
			RESTART : IN STD_LOGIC;
			FRAME_COUNTER : IN INTEGER RANGE 0 TO 59; --frame tracking for animation(1 to 60 frames)
			X : IN INTEGER RANGE 0 TO 800; --Horizontal pixel position of VGA being rendered (to calculate and draw object at correct position)
			Y : IN INTEGER RANGE 0 TO 600; --Vertical pixel position of VGA being rendered (to calculate and draw object at correct position)
			ACC_X : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --x-axis acceleration data
			ACC_Y : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --y-axis acceleration data
			ACC_Z : IN STD_LOGIC_VECTOR(15 DOWNTO 0); --z-axis acceleration data
			COLOR : OUT STD_LOGIC_VECTOR(11 DOWNTO 0); --Use to set color of each pixel
			SSW : IN STD_LOGIC_VECTOR(1 DOWNTO 0) --Slide switch data for set ball speed
		);
	END COMPONENT;

BEGIN

	C : vga_clk_40 PORT MAP(CLOCK_50, VGACLK);
	C1 : SYNC PORT MAP(VGACLK, VGA_HS, VGA_VS, VGA_R, VGA_G, VGA_B, FRAME_COUNTER, X, Y, COLOR);
	C2 : pmod_accelerometer_adxl345 GENERIC MAP(clk_freq => 50, data_rate => "1011", data_range => "00")
	PORT MAP(CLOCK_50, NOT RESET, miso, sclk, ss_n, mosi, ACC_X, ACC_Y, ACC_Z);
	C3 : Game_Logic PORT MAP(VGACLK, RESTART, FRAME_COUNTER, X, Y, ACC_X, ACC_Y, ACC_Z, COLOR, SSW);

END MAIN;