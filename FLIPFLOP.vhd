library IEEE;
use ieee.std_logic_1164.all;

entity FLIPFLOP is
	port (D : in std_logic_vector (9 downto 0);
			CLK, N_RST, EN : in std_logic;
			Q : out std_logic_vector(9 downto 0));
			
end entity;

architecture ARC of FlipFlop is 

begin 

	process (CLK, N_RST, EN)
	
		begin 
			if EN = '0' then
				NULL;
			elsif N_RST = '0' then
				Q <= "0000000000";
			elsif (CLK'event and CLK = '1') then
				Q <= D;
			end if;
			
	end process; 
	
end ARC;
