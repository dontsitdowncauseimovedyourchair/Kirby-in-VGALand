library IEEE;
use IEEE.std_logic_1164.all;

entity CONTADOR525 is
	port ( CLK, RST, EN : in std_logic;
			 Cuenta : out std_logic_vector(9 downto 0);
			 Overflow : out std_logic);
end entity CONTADOR525;

architecture ARC of CONTADOR525 is 

	component SUMADOR10 is 
		port (A: in std_logic_vector(9 downto 0);
				S : out std_logic_vector(9 downto 0);
				Cout : out std_logic);
	end component;
	
	component FLIPFLOP is 
	port (D : in std_logic_vector(9 downto 0);
			CLK, N_RST, EN : in std_logic;
			Q : out std_logic_vector(9 downto 0));
	end component;
	
signal entrada, salida, suma: std_logic_vector(9 downto 0);
signal coutsum : std_logic;


begin

F1 : FLIPFLOP port map (entrada, CLK, RST, EN, salida);

S1 : SUMADOR10 port map (salida, suma, coutsum);
		
process(salida, suma, RST)
    begin
        if salida = "1000001100" then
            entrada <= "0000000000";
            Overflow <= '1';
        else
            entrada <= suma;
            Overflow <= '0';
        end if;
    end process;		
		
Cuenta <= salida;

end ARC;