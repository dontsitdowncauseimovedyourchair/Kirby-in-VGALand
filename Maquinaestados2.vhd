library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity Maquinaestados2 is
	port (CLK, RST : in std_logic;
			CONTADOR525 : in std_logic_vector(9 downto 0);
			CONTADOR800 : in std_logic_vector(9 downto 0);
			VSYNCEST : in std_logic_vector (1 downto 0);
			DIBUJA : out std_logic;
			HSYNC : out std_logic);
			
end entity;

architecture ARC of Maquinaestados2 is
	
	type ESTADO is (IDLE, PSY, BP, DI, FP);
	signal EDO, EDO_F : ESTADO;
	
	begin 
	
	P1 : process(CLK, RST) 
					begin
						if (RST = '0') then 
							EDO <= IDLE;
						elsif (CLK'event and CLK = '1') then 
							EDO <= EDO_F;
						end if;
				end process P1;
				
				
	P2 : process(EDO, CONTADOR800)
			begin
			case (EDO) is
			
				when IDLE => if (CONTADOR800 = "0000000000") then
						EDO_F <= PSY;
						
						else
						
						EDO_F <= IDLE;
						
						end if;

				when PSY => if (CONTADOR800 = "0001011111") then
						EDO_F <= BP;
						
						else
						
						EDO_F <= PSY;
						
						end if;
						
				when BP => if (CONTADOR800 = "0010001111") then
						EDO_F <= DI;
						
						else
						
						EDO_F <= BP;
						
						end if;
						
				when DI => if (CONTADOR800 = "1100001111") then 
						EDO_F <= FP;
						
						else 
						
						EDO_F <= DI;
						
						end if;
						
				when FP => if (CONTADOR800 = "1100011111") then 
						EDO_F <= IDLE;
						
						else
		
						EDO_F <= FP;
						
						end if;
			end case;
		end process P2;
		
		
	P3 : process (EDO, VSYNCEST, CONTADOR800, CONTADOR525)
	
		begin
			 if EDO = PSY then
				  HSYNC <= '0';
			 else
				  HSYNC <= '1';
			 end if;
			 
			 
	end process P3;

	P4 : process (EDO, VSYNCEST)
		begin 
		
		if EDO = DI AND VSYNCEST <= "10" then
					DIBUJA <= '1';
		else 
		DIBUJA <= '0';
		
		end if; 
	end process P4;
			
end ARC; 