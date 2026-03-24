--Game Engine - Kirby in Papulandia


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GAME_ENGINE is
	port (	
		 CLK50 : in std_logic; --Para sincronía con todo el juego
	    SE_DIBUJO : in std_logic;  --CONTADOR 525 Overflow
		 LOGICAR : out std_logic; --Tick del juego que indica que ya se completó un ciclo de dibujado
		 StartGame: in std_logic; --Entrada de empezar el juego
		
		 ESTADOJUEGO : out std_logic_vector(1 downto 0);	--Estado del juego
		 
		 VIDA_K : in integer range 0 to 14;  --Vida de Kirby
		 ATAQUE_K : in std_logic;				--Señal de Ataque de Kirby
		 VOLANDO_EK : in std_logic_vector(2 downto 0);	--Banderas para saber si las estrellas van volando
		
		 VIDA_V : in integer range 0 to 14;	--Vida del Villano
		 ATAQUE_V : in std_logic_vector(1 downto 0); --Señal de Ataque del Villano
		 VOLANDO_EV : in std_logic_vector(3 downto 0);  --Banderas para saber si las estrellas van volando
		
		--Posición de Kirby
		 KIRBY_X : in integer range 0 to 799;	
		 KIRBY_Y : in integer range 0 to 524;
		
		--Posición de Villano
		 VILLANO_X : in integer range 0 to 799;
		 VILLANO_Y : in integer range 0 to 524;
		 
		 --Posición de Estrellas de Kirby
		 ESTRELLAK1_X : in integer range 0 to 799;
		 ESTRELLAK1_Y : in integer range 0 to 524;
		 ESTRELLAK2_X : in integer range 0 to 799;
		 ESTRELLAK2_Y : in integer range 0 to 524;
		 ESTRELLAK3_X : in integer range 0 to 799;
		 ESTRELLAK3_Y : in integer range 0 to 524;
		 
		 --Posición de Posiciones iniciales
		 I_ESTRELLAK1_X : out integer range 0 to 799;
		 I_ESTRELLAK1_Y : out integer range 0 to 524;
		 I_ESTRELLAK2_X : out integer range 0 to 799;
		 I_ESTRELLAK2_Y : out integer range 0 to 524;
		 I_ESTRELLAK3_X : out integer range 0 to 799;
		 I_ESTRELLAK3_Y : out integer range 0 to 524;

		 --Posición de Estrellas del Villano
		 ESTRELLAV1_X : in integer range 0 to 799;
		 ESTRELLAV1_Y : in integer range 0 to 524;
		 ESTRELLAV2_X : in integer range 0 to 799;
		 ESTRELLAV2_Y : in integer range 0 to 524;
		 ESTRELLAV3_X : in integer range 0 to 799;
		 ESTRELLAV3_Y : in integer range 0 to 524;
		 ESTRELLAV4_X : in integer range 0 to 799;
		 ESTRELLAV4_Y : in integer range 0 to 524;
		 
		 --Posición de Posiciones iniciales
		 I_ESTRELLAV1_X : out integer range 0 to 799;
		 I_ESTRELLAV1_Y : out integer range 0 to 524;
		 I_ESTRELLAV2_X : out integer range 0 to 799;
		 I_ESTRELLAV2_Y : out integer range 0 to 524;
		 I_ESTRELLAV3_X : out integer range 0 to 799;
		 I_ESTRELLAV3_Y : out integer range 0 to 524;
		 I_ESTRELLAV4_X : out integer range 0 to 799;
		 I_ESTRELLAV4_Y : out integer range 0 to 524;
		 
		 --Velocidad inicial de la estRELLAK1_X
		 I_ESTRELLAV_VX : out integer range -10 to 10;
		 I_ESTRELLAV_VY : out integer range -10 to 10;
		 
		 --Señales de cuando las estrellas de Kirby son aventadas y cuando explotan
		 AVENTAR_K, PUF_ESTRELLAK : out std_logic_vector(2 downto 0); 
		 
		 --Daño a Kirby y daño al villano
		 DANO_V, DANO_K : out std_logic;
		 
		 --Señales de los tipos de estrella que aventará el villano
		 TIPO_ESTRELLA : out std_logic_vector(7 downto 0);
		 
		 --Señales de cuando las estrellas de Kirby son aventadas, cuando explotan y cuando prepara el ataque
		 AVENTAR_V, PUF_ESTRELLAV, PREPARAR_V: out std_logic_vector(3 downto 0)
	);
end entity;


architecture ARC of GAME_ENGINE is

	--Señales de sinconía para la lógica del juego
	signal se_dibujo_sync1 : std_logic := '0';
   signal se_dibujo_sync2 : std_logic := '0';
   signal SE_DIBUJO_PREV : std_logic := '0';
   signal FRAME : std_logic; --Señal de sincronía que indica que un frame se completó de dibujar

	
	--Estados del juego
	type JUEGOESTADOS is (INIT, SEJUEGA, FLOP, FLIP);
	signal EDO: JUEGOESTADOS := INIT;
	signal EDO_F : JUEGOESTADOS := INIT;
	
	--Altura y Anchura de Kirby
	constant KIRBY_W : integer := 32;
	constant KIRBY_H : integer := 32;
	
	--Altura y Anchura del Villano
	constant VILLANO_W : integer := 64;
	constant VILLANO_H : integer := 64;
	
	--Altura y anchura de las estrellas de las estrellas
	constant ESTRELLAK_W : integer := 16;
	constant ESTRELLAK_H : integer := 16;
	constant ESTRELLAV_W : integer := 32;
	constant ESTRELLAV_H : integer := 32;

	--Arrays de las estrellas
	type POS_E_X is array (0 to 3) of integer range 0 to 799;
	type POS_E_Y is array (0 to 3) of integer range 0 to 524;
	
	--KIRBY
	signal S_DANO_K : std_logic;
	signal S_DANOMELEE_K : std_logic;
	signal S_DANO_V : std_logic;
	
	--Estrellas de kirby
	signal S_I_ESTRELLASK_X : POS_E_X := (0, 0, 0, 0);
	signal S_I_ESTRELLASK_Y : POS_E_Y := (0, 0, 0, 0);
	signal S_AVENTAR_K, S_PUF_ESTRELLAK : std_logic_vector(2 downto 0);
		
	--Estrellas del villano
	signal S_I_ESTRELLASV_X : POS_E_X := (0, 0, 0, 0);
	signal S_I_ESTRELLASV_Y : POS_E_Y := (0, 0, 0, 0);
	signal S_AVENTAR_V, S_PUF_ESTRELLAV, S_PREPARAR_V : std_logic_vector(3 downto 0);
	
	--Timer de preparar un ataque del villano
	signal timer_prep : integer range 0 to 127;
	
	begin
	
	--ESTADOS DEL JUEGO 
	--00 : INICIAL
	--01 : JUGANDO
	--10 : MURIÓ
	--11 : GANÓ
	
	ESTADOJUEGO <= "00" when EDO = INIT else
						"01" when EDO = SEJUEGA else
						"10" when EDO = FLOP else 
						"11";
	
	--Asignar las señales que cambian los process
	
	LOGICAR <= FRAME; 
						
	AVENTAR_K <= S_AVENTAR_K;
	PUF_ESTRELLAK <= S_PUF_ESTRELLAK;
	AVENTAR_V <= S_AVENTAR_V;
	PUF_ESTRELLAV <= S_PUF_ESTRELLAV;
	PREPARAR_V <= S_PREPARAR_V;
					
	DANO_K <= S_DANO_K or S_DANOMELEE_K;
	DANO_V <= S_DANO_V;
	
	--Saber el estado pasado de se dibujo
	HUBO_DIBUJO : process(CLK50)
    begin
        if (CLK50'event and CLK50 = '1') then
            se_dibujo_sync1 <= SE_DIBUJO;
            se_dibujo_sync2 <= se_dibujo_sync1;
            SE_DIBUJO_PREV  <= se_dibujo_sync2;
        end if;
    end process;
	
	--Para evitar que los procesos corran arduas veces (Me ayudó gemini)
	FRAME <= '1' when (se_dibujo_sync2 = '1' and SE_DIBUJO_PREV = '0') else '0';	
	
	CLOCK : process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1') then --Sincronizar los procesos eficientemente con el Reloj de 50MHz
				if (FRAME = '1') then	--Cuando se tiene un frame finalizado
					EDO <= EDO_F;
					
					--Timer de preparación de ataques del villano (usado en ataque 4)
					if (ATAQUE_V = "11" and timer_prep = 0) then
						timer_prep <= 20;
					elsif (timer_prep > 0) then
						timer_prep <= timer_prep - 1;
					end if;
				end if;
			end if;
	end process;
	
	--Multiplexeo de los estados del juego
	EDOOO : process(EDO, StartGame)
		begin
		EDO_F <= EDO;
		
		case EDO is
		--Esperar a que se presione play
			when INIT => 
				if(StartGame = '0') then
					EDO_F <= SEJUEGA;
				 else
					EDO_F <= INIT;
				 end if;
							
			--Peleando con el boss
			when SEJUEGA => 
				if (VIDA_K = 0) then
					EDO_F <= FLOP;
				elsif (VIDA_V = 0) then
					EDO_F <= FLIP;
				else
					EDO_F <= SEJUEGA;
				end if;
			
			
			--MURIÓ
			when FLOP => 
				 if(StartGame = '0') then
					EDO_F <= INIT;
				 else
					EDO_F <= FLOP;
				 end if;
				
			--GANÓ
			when FLIP => 
				 if(StartGame = '0') then
					EDO_F <= INIT;
				 else
					EDO_F <= FLIP;
				 end if;
		end case;
	end process;
		
	--AVentar Estrella de Kirby
	ESTRELLAR: process(CLK50)
		begin
		if (CLK50'event and CLK50 = '1') then	
			if (FRAME = '1') then
			
				S_AVENTAR_K <= "000";
				
				case EDO is 
					when SEJUEGA =>
						if (ATAQUE_K = '1') then 
						--Checar cuál estrella está disponible y aventar la primera disponible.
							if (VOLANDO_EK(0) = '0') then
								I_ESTRELLAK1_X <= KIRBY_X + KIRBY_W;
								I_ESTRELLAK1_Y <= KIRBY_Y + 8;
								S_AVENTAR_K(0) <= '1';
							elsif (VOLANDO_EK(1) = '0') then
								I_ESTRELLAK2_X <= KIRBY_X + KIRBY_W;
								I_ESTRELLAK2_Y <= KIRBY_Y + 8;
								S_AVENTAR_K(1) <= '1';
							elsif (VOLANDO_EK(2) = '0') then
								I_ESTRELLAK3_X <= KIRBY_X + KIRBY_W;
								I_ESTRELLAK3_Y <= KIRBY_Y + 8;
								S_AVENTAR_K(2) <= '1';
							end if;
						end if;
					when others => Null;
				end case;
			end if;
		end if;
	end process;
	
	--Aventar estrella del villano
	ESTRELLADO : process(CLK50)
		begin
			if (CLK50'event and CLK50 = '1')	then
				if (FRAME = '1') then

					--Defaults
					S_AVENTAR_V <= "0000";
					S_PREPARAR_V <= "0000";
				
					case EDO is					
						when SEJUEGA =>
							
							if (ATAQUE_V = "11" or timer_prep > 0) then --Ataque de 4 estrellas
							
								--Posicionar las estrellas
								I_ESTRELLAV1_X <= VILLANO_X - 32;
								I_ESTRELLAV1_Y <= VILLANO_Y - 80;
								
								I_ESTRELLAV2_X <= VILLANO_X - 64;
								I_ESTRELLAV2_Y <= VILLANO_Y - 40;
								
								I_ESTRELLAV3_X <= VILLANO_X - 64;
								I_ESTRELLAV3_Y <= VILLANO_Y + 40;
								
								I_ESTRELLAV4_X <= VILLANO_X - 32;
								I_ESTRELLAV4_Y <= VILLANO_Y + 80;
								
								I_ESTRELLAV_VX <= -10;
								I_ESTRELLAV_VY <= 0;
								TIPO_ESTRELLA <= X"00";
								
								--Posicionar las estrellas sin aventarlas
								if (timer_prep > 1 or ATAQUE_V = "11") then
									S_PREPARAR_V <= "1111";
								else --Timer llegó a cero
									S_AVENTAR_V <= "1111"; --Aventar todas a la vez
								end if;
								
								TIPO_ESTRELLA <= X"00"; --Estrellas derechas todas

								
							elsif (ATAQUE_V /= "00") then	--Si hay algún tipo de ataque --Ataques secuenciales
							--Checar cuál estrella está disponible.
								if (VOLANDO_EV(0) = '0') then --Si la estrella 1 no está volando
								--Posicionarla y aventarla
									I_ESTRELLAV1_X <= VILLANO_X - 32;
									I_ESTRELLAV1_Y <= VILLANO_Y + 16;
									I_ESTRELLAV_VX <= -7;
									I_ESTRELLAV_VY <= 0;
									S_AVENTAR_V(0) <= '1';
									
									case ATAQUE_V is
										when "01" => 	--Ataque derecho
											TIPO_ESTRELLA(1 downto 0) <= "00";
										when "10" =>	--Ataque guiado
											TIPO_ESTRELLA(1 downto 0) <= "01";
										when others => null;
									end case;
									
								elsif (VOLANDO_EV(1) = '0') then
									I_ESTRELLAV2_X <= VILLANO_X - 32;
									I_ESTRELLAV2_Y <= VILLANO_Y + 16;
									I_ESTRELLAV_VX <= -7;
									I_ESTRELLAV_VY <= 0;
									S_AVENTAR_V(1) <= '1';
									
									case ATAQUE_V is
										when "01" => 
											TIPO_ESTRELLA(3 downto 2) <= "00";
										when "10" =>
											TIPO_ESTRELLA(3 downto 2) <= "01";
										when others => null;
									end case;
									
								elsif (VOLANDO_EV(2) = '0') then
									I_ESTRELLAV3_X <= VILLANO_X - 32;
									I_ESTRELLAV3_Y <= VILLANO_Y + 16;
									I_ESTRELLAV_VX <= -7;
									I_ESTRELLAV_VY <= 0;
									S_AVENTAR_V(2) <= '1';
									
									case ATAQUE_V is
										when "01" => 
											TIPO_ESTRELLA(5 downto 4) <= "00";
										when "10" =>
											TIPO_ESTRELLA(5 downto 4) <= "01";
										when others => null;
									end case;
									
									
								elsif (VOLANDO_EV(3) = '0') then
									I_ESTRELLAV4_X <= VILLANO_X - 32;
									I_ESTRELLAV4_Y <= VILLANO_Y + 16;
									I_ESTRELLAV_VX <= -7;
									I_ESTRELLAV_VY <= 0;
									S_AVENTAR_V(3) <= '1';
									
									case ATAQUE_V is
										when "01" => 
											TIPO_ESTRELLA(7 downto 6) <= "00";
										when "10" =>
											TIPO_ESTRELLA(7 downto 6) <= "01";
										when others => null;
									end case;
								end if;
							end if;

						when others => Null;
					end case;
				end if;
			end if;
	end process;
	
	
	--Colisiones con Kirby
	PUFFEADOR_K : process(CLK50)
		begin
		if (CLK50'event and CLK50 = '1')	then
			if (FRAME = '1') then
			
				--Resetear para evitar spammear
				S_PUF_ESTRELLAV <= "0000";
				S_DANO_K <= '0';
				
				
				
				case EDO is
					when SEJUEGA => 
						--Checar si las posiciones y su altura y anchura de la estrella están dentro de Kirby
						if (ESTRELLAV1_X < KIRBY_X + KIRBY_W and ESTRELLAV1_X + ESTRELLAV_W > KIRBY_X 
						and ESTRELLAV1_Y < KIRBY_Y + KIRBY_H and ESTRELLAV1_Y + ESTRELLAV_H > KIRBY_Y) then
							--Hacerle puff y dañar a kirby
							S_PUF_ESTRELLAV(0) <= '1';
							S_DANO_K <= '1';
						end if;	
						
						if (ESTRELLAV2_X < KIRBY_X + KIRBY_W and ESTRELLAV2_X + ESTRELLAV_W > KIRBY_X 
						and ESTRELLAV2_Y < KIRBY_Y + KIRBY_H and ESTRELLAV2_Y + ESTRELLAV_H > KIRBY_Y) then
							S_PUF_ESTRELLAV(1) <= '1';
							S_DANO_K <= '1';
						end if;
						if (ESTRELLAV3_X < KIRBY_X + KIRBY_W and ESTRELLAV3_X + ESTRELLAV_W > KIRBY_X 
						and ESTRELLAV3_Y < KIRBY_Y + KIRBY_H and ESTRELLAV3_Y + ESTRELLAV_H > KIRBY_Y) then
							S_PUF_ESTRELLAV(2) <= '1';
							S_DANO_K <= '1';
						end if;	
						if (ESTRELLAV4_X < KIRBY_X + KIRBY_W and ESTRELLAV4_X + ESTRELLAV_W > KIRBY_X 
						and ESTRELLAV4_Y < KIRBY_Y + KIRBY_H and ESTRELLAV4_Y + ESTRELLAV_H > KIRBY_Y) then
							S_PUF_ESTRELLAV(3) <= '1';	
							S_DANO_K <= '1';
						end if;
					when others => 
						S_PUF_ESTRELLAV <= "0000";
						S_DANO_K <= '0';
				end case;
			end if;
		end if;
	end process;
	
	--Colisiones con el villano
	PUFFEADOR_V : process(CLK50)
		begin
		if (CLK50'event and CLK50 = '1')	then
			if (FRAME = '1') then
			--Default
				S_PUF_ESTRELLAK <= "000";
				S_DANO_V <= '0';
				
				case EDO is 
					when SEJUEGA =>
						--Checar si las posiciones y su altura y anchura de la estrella están dentro del Villano
						if (ESTRELLAK1_X < VILLANO_X + VILLANO_W and ESTRELLAK1_X + ESTRELLAK_W > VILLANO_X
						and ESTRELLAK1_Y < VILLANO_Y + VILLANO_H and ESTRELLAK1_Y + ESTRELLAK_H > VILLANO_Y) then
							--Hacerle puff y dañar al villano
							S_PUF_ESTRELLAK(0) <= '1';
							S_DANO_V <= '1';
						end if;
						
						if (ESTRELLAK2_X < VILLANO_X + VILLANO_W and ESTRELLAK2_X + ESTRELLAK_W > VILLANO_X
						and ESTRELLAK2_Y < VILLANO_Y + VILLANO_H and ESTRELLAK2_Y + ESTRELLAK_H > VILLANO_Y) then
							S_PUF_ESTRELLAK(1) <= '1';
							S_DANO_V <= '1';
						end if;
						
						if (ESTRELLAK3_X < VILLANO_X + VILLANO_W and ESTRELLAK3_X + ESTRELLAK_W > VILLANO_X
						and ESTRELLAK3_Y < VILLANO_Y + VILLANO_H and ESTRELLAK3_Y + ESTRELLAK_H > VILLANO_Y) then
							S_PUF_ESTRELLAK(2) <= '1';
							S_DANO_V <= '1';
						end if;
						
					when others => --No puffea nada cuando hay otros estados
						S_PUF_ESTRELLAK <= "000";
						S_DANO_V <= '0';
				end case;
			end if;
		end if;
	end process;
	
	
	--Golpe directo del villano 
	MELEE : process(CLK50)
		begin
			if (CLK50'event and CLK50 = '1')	then
				if (FRAME = '1') then
				S_DANOMELEE_K <= '0';
					case EDO is 
					--Las hitboxes están un poco reducidas para que no se sienta tan injusto
						when SEJUEGA =>
							if ( (KIRBY_X + 4) < (VILLANO_X + 60) and  
									 (KIRBY_X + 28) > (VILLANO_X + 4) and  
									 (KIRBY_Y + 4) < (VILLANO_Y + 60) and  
									 (KIRBY_Y + 28) > (VILLANO_Y + 4) ) then 
									S_DANOMELEE_K <= '1';
                    end if;
					  when others => null;
					end case;
				end if;
			end if;
	end process;
	
end architecture;