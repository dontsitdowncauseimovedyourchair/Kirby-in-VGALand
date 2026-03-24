library IEEE;
use IEEE.std_logic_1164.ALL;

entity SUMADOR10 is
	port (A: in std_logic_vector(9 downto 0);
			S : out std_logic_vector(9 downto 0);
			Cout : out std_logic);
	end SUMADOR10;

architecture ARC of SUMADOR10 is
	
signal salida, suma : std_logic_vector(9 downto 0);

component HA is 
	port (A, B : in std_logic;             
			S, Cout : out std_logic);
end component; 

begin

I1 : HA port map (A(0), '1', suma(0), salida(0));
I2 : HA port map (A(1), salida(0), suma(1), salida(1));
I3 : HA port map (A(2), salida(1), suma(2), salida(2));
I4 : HA port map (A(3), salida(2), suma(3), salida(3));
I5 : HA port map (A(4), salida(3), suma(4), salida(4));
I6 : HA port map (A(5), salida(4), suma(5), salida(5));
I7 : HA port map (A(6), salida(5), suma(6), salida(6));
I8 : HA port map (A(7), salida(6), suma(7), salida(7));
I9 : HA port map (A(8), salida(7), suma(8), salida(8));
I10 : HA port map (A(9), salida(8), suma(9), cout);
	
S <= suma;
	
end ARC;