--Medio sumador

library IEEE;
use ieee.std_logic_1164.all;

entity HA is 
	port (A, B : in std_logic;             -- Al ser el medio sumador solo tiene dos entradas y dos salidas
			S, Cout : out std_logic);
end entity; 

architecture ARC of HA is 
	-- Aquí es donde se describen los componentes y las señales de interconexión
	
	begin 
		-- Asignamos las salidas      <= es el símbolo de asignación 
			S <= A xor B;
			Cout <= 	A and B;
			
end architecture;

