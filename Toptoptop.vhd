library IEEE;
use IEEE.std_logic_1164.all;

entity Toptoptop is 
	port (CLK, RST, EN: in std_logic;
			VSYNC : out std_logic;
			B , G, R : out std_logic_vector(2 downto 0);
			HSYNC : out std_logic;
			OFLOW : out std_logic);
end entity;

architecture ARC of Toptoptop is

component DIVFREC is
	port (CLK, RST: in std_logic;
			F : out std_logic);
end component;

component CONTADOR800 is 
	port (CLK, RST, EN : in std_logic;
			 Cuenta : out std_logic_vector(9 downto 0);
			 Overflow : out std_logic);
end component;

component CONTADOR525 is 
	port (CLK, RST, EN : in std_logic;
			 Cuenta : out std_logic_vector(9 downto 0);
			 Overflow : out std_logic);
end component CONTADOR525;

component Maquinaestados1 is
	port (CLK, RST : in std_logic;
			CONTADOR525 : in std_logic_vector (9 downto 0);
			VSYNC : out std_logic;
			VSYNCEST : out std_logic_vector(1 downto 0));
end component;

component Maquinaestados2 is 
	port (CLK, RST : in std_logic;
			CONTADOR525 : in std_logic_vector(9 downto 0);
			CONTADOR800 : in std_logic_vector(9 downto 0);
			VSYNCEST : in std_logic_vector (1 downto 0);
			B , G, R: out std_logic_vector(2 downto 0);
			HSYNC : out std_logic);
end component;

signal Freq : std_logic;
signal CNT : std_logic_vector(9 downto 0);
signal Over : std_logic;
signal CNT2 : std_logic_vector(9 downto 0);
signal VESYNCEST : std_logic_vector(1 downto 0);

begin 

I1 : DIVFREC port map (CLK, RST, Freq);
I2 : CONTADOR800 port map (Freq, RST, EN, CNT, Over);
I3 : CONTADOR525 port map (Freq, RST, Over, CNT2, OFLOW);
I4 : Maquinaestados1 port map (Freq, RST, CNT2, VSYNC, VESYNCEST);
I5 : Maquinaestados2 port map (Freq, RST, CNT2, CNT, VESYNCEST, B, G, R, HSYNC);


end ARC;
