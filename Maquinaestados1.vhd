library IEEE;
use IEEE.std_logic_1164.all;

entity Maquinaestados1 is
	port (CLK, RST : in std_logic;
			CONTADOR525 : in std_logic_vector (9 downto 0);
			VSYNC : out std_logic;
			ESTADOS_TST : out	std_logic_vector(2 downto 0);
			VSYNCEST : out std_logic_vector(1 downto 0));
end entity;
	
	
architecture ARC of Maquinaestados1 is 

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

		P2 : process(EDO, CONTADOR525)
			begin
			case (EDO) is
			
				when IDLE => if (CONTADOR525 = "0000000000") then
						EDO_F <= PSY;
						
						else
						
						EDO_F <= IDLE;
						
						end if;

				when PSY => if (CONTADOR525 = "0000000001") then
						EDO_F <= BP;
						
						else
						
						EDO_F <= PSY;
						
						end if;
						
				when BP => if (CONTADOR525 = "0000100010") then
						EDO_F <= DI;
						
						else
						
						EDO_F <= BP;
						
						end if;
						
				when DI => if (CONTADOR525 = "1000000010") then 
						EDO_F <= FP;
						
						else 
						
						EDO_F <= DI;
						
						end if;
						
				when FP => if (CONTADOR525 = "1000001100") then 
						EDO_F <= IDLE;
						
						else
		
						EDO_F <= FP;
						
						end if;
			end case;
		end process P2;

		P3 : process (EDO)
		begin 
			case (EDO) is
				
				when IDLE => VSYNC <= '0';
								VSYNCEST <= "00";
								ESTADOS_TST <= "000";
			
				when PSY => VSYNC <= '0';
								VSYNCEST <= "00";
								ESTADOS_TST <= "001";
			
				when BP => VSYNC <= '1';
							  VSYNCEST <= "01";
							  ESTADOS_TST <= "010";
				
				when DI => VSYNC <= '1';
							  VSYNCEST <= "10";
							  ESTADOS_TST <= "011";
								
				when FP => VSYNC <= '1';
							  VSYNCEST <= "11";
							  ESTADOS_TST <= "100";
							  
				when others => null;
			end case; 
		end process P3;
			
end ARC;

	

