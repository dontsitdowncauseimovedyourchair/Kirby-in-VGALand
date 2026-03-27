library IEEE;
use ieee.std_logic_1164.all;

entity DIVFREC is
	port (CLK, RST: in std_logic;
			F : out std_logic);
end entity;

architecture RTL of DIVFREC is
	signal Q: std_logic; 
	
	begin 
	P1: process (CLK, RST)
		begin
			if RST = '0' then 
			Q <= '0';
			elsif CLK'event and CLK = '1' then
			Q <= NOT(Q);
			end if;
	end process;
	
	F <= Q;
	
end architecture; 