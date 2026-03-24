--VILLANO - Kirby in Papulandia

library IEEE;
use ieee.std_logic_1164.all;
--use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity VILLANO is 
	port (
		CLK50 : in std_logic;		--Reloj de de 50MHz
		FRAME : in std_logic;
		ESTADOJUEGO : in std_logic_vector(1 downto 0);   --siguiente frame
		
		AUCH : in std_logic;		--Señal de daño
		
		KIRBY_X : in integer range 0 to 799;	--Posiciones de kirby
		KIRBY_Y : in integer range 0 to 524;
		
		VILLANO_X : out integer range 0 to 799;	--Posiciones del villano
		VILLANO_Y : out integer range 0 to 524;
		
		VIDA_V : out integer range 0 to 14; 	--Vida del villano
		
		ATACA : out std_logic_vector(1 downto 0); --Si ataca o no y el tipo de ataque
		
		SPRITE : out integer range 0 to 1		--Sprite a usar en el dibujador
	);
end entity;

--Ataques
--00: no ataCA
--01: ataca derecho
--10: ataca dirigido
--11: ANDO DELULU NO SE SI DE TIEMPO DE PONER MÁS

architecture ARC of VILLANO is

	--Estados del villano (IDLE, Estado entre ataques, diferentes tipos de ataque, fallecer)
	type ESTADO_VILLANO is (IDLE, MOVER, ATAQUE1, ATAQUE2, ATAQUE3, ATAQUE4, MORIR);
	signal EDO, EDO_F : ESTADO_VILLANO := IDLE;
	
	--Constantes de limites del front porch para no tener que andar acordándome
	constant TOPE_SUP : integer := 100;
	constant TOPE_INF : integer := 400;
	constant TOPE_IZQ : integer := 143; 
   constant TOPE_DER : integer := 783;
	
	--Constante de las posiciones iniciales
	constant POS_INICIAL_X : integer := 650;
	constant POS_INICIAL_Y : integer := 253;

	--Timer entre estados
	signal timer : integer range 0 to 1023 := 60;
		
	--Timer de invencibilidad cuando le pegan
	signal timer_i : integer range 0 to 1023 := 0;
	
	--Timer del sprite de ataque
	signal timer_sprite_at : integer range 0 to 127;
	
	
	signal S_VILLANO_X : integer range 0 to 799 := 650; --Posición x
	signal S_VILLANO_Y : integer range 0 to 524 := 263; --Posición y
	signal S_VILLANO_VX : integer range -10 to 10 := 0; --Velocidad x
	signal S_VILLANO_VY : integer range -10 to 10 := 0; --Velocidad y
	
	signal S_DESTINO_Y : integer range 0 to 524 := 263; --Destino del movimientos del villano
	signal S_DESTINO_X : integer range 0 to 799 := 650; 
	
	signal S_HABEMUS_MELEE : std_logic;		--Bandera para llevar registro del ataque melee del villano
	
	signal S_VIDA_V : integer range 0 to 14 := 10; --Vida del villano
	signal S_ATACA : std_logic_vector(1 downto 0);	--Ataque y su tipo
	
	signal valorRNG : std_logic_vector(15 downto 0) := X"1AF8"; --Número random para que sea dinámico
	signal timer_a : integer range 0 to 255;	--Timer de cuándo mandar un ataque
	
	--Direccion -1: arriba, 0: nada, 1: abajo.
	signal DIR_VY : integer range -1 to 1 := 0; --Direccion del villano en Y
	--Direccion -1: izquierda, 0: nada, 1: derecha.
	signal DIR_VX : integer range -1 to 1 := 0; --Dirección en x
	
	signal S_SPRITE : integer range 0 to 1; --Sprite para el dibujador
	
	
	begin
	
	VILLANO_X <= S_VILLANO_X;
	VILLANO_Y <= S_VILLANO_Y;
	VIDA_V <= S_VIDA_V;
	ATACA <= S_ATACA;
	SPRITE <= S_SPRITE;
	
	--Process para los tiempos
	CLOCK : process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1') then	
				if (FRAME = '1') then
					EDO <= EDO_F;
					
					if (timer = 0 or ESTADOJUEGO = "00") then
						--Tiempos de cada estado, se aplican en el estado futuro EDO_F o sino se buggea.
						case EDO_F is
							when IDLE => timer <= 1;
							when MOVER => timer <= 30 + to_integer(unsigned(valorRNG(3 downto 0)));
							when ATAQUE1 => timer <= 250 + to_integer(unsigned(valorRNG(6 downto 0))); 
							when ATAQUE2 => timer <= 250 + to_integer(unsigned(valorRNG(6 downto 0))); 
							when ATAQUE3 => timer <= 201;
							when ATAQUE4 => timer <= 999; --Acaba cuando llega de regreso, no ocupa un timer
							when others => timer <= 0;
						end case;
					elsif (EDO = ATAQUE4 and S_HABEMUS_MELEE = '1' and S_VILLANO_X >= POS_INICIAL_X - 8) then --Para terminar el ataque 4
						timer <= 0;
					else
					--Timer baja cada frame
						timer <= timer - 1;
					end if;
					
					if(timer_i > 0) then
						timer_i <= timer_i - 1;
					elsif (timer_i = 0 and AUCH = '1') then
						timer_i <= 20;
					end if;
					
					--timer de ataques
					if (timer_a = 0) then
						case EDO is
							when ATAQUE1 =>
								timer_a <= 20 + to_integer(unsigned(valorRNG(4 downto 0))); --Valores random
							when ATAQUE2 =>
								timer_a <= 30 + to_integer(unsigned(valorRNG(4 downto 0)));
							when ATAQUE3 =>
								timer_a <= 80;
							when ATAQUE4 =>
								timer_a <= 100;
							
							when others => timer_a <= 0;
						end case;
					else 
						timer_a <= timer_a - 1;
					end if;
					
					--timer del sprite
					if (timer_sprite_at > 0) then
						timer_sprite_at <= timer_sprite_at - 1;
					elsif(s_ATACA /= "00") then
						timer_sprite_at <= 7;
					end if;
					
				end if;
			end if;
	end process;
	
	
	--Process para cambiar de estado
	EDOOO : process(EDO, ESTADOJUEGO, S_VIDA_V, timer) 
		begin
		--Default
		EDO_F <= EDO;
		
		--ESTADOS DEL JUEGO JUGADOR
			--00 : INICIAL
			--01 : JUGANDO
			--10 : MURIÓ
			--01 : GANÓ
		case ESTADOJUEGO is
			when "00" => EDO_F <= IDLE;
			
			when "01" => 
			--Ver si ya se murió
				if (S_VIDA_V = 0) then
					EDO_F <= MORIR;
				elsif (timer = 0) then --Pasar a otro estado de ataque
					case EDO is
						when IDLE => EDO_F <= MOVER;
						when MOVER => 			--Elegir otro ataque
							case VALorRNG(1 downto 0) is
								when "00" =>		
									EDO_F <= ATAQUE1;
								when "01" =>
									EDO_F <= ATAQUE2;
								when "10" =>
									EDO_F <= ATAQUE3;
								when others => 
									EDO_F <= ATAQUE4;
							end case;
						when ATAQUE1 => EDO_F <= MOVER;
						when ATAQUE2 => EDO_F <= MOVER;
						when ATAQUE3 => EDO_F <= MOVER;
						when ATAQUE4 => EDO_F <= MOVER;
						when others => EDO_F <= MOVER;
					end case;
				else  --El timer sigue bajando, mantengo el estado
					EDO_F <= EDO;
				end if;
				
			when "10" => EDO_F <= IDLE;
			when "11" => EDO_F <= MORIR;
		end case;
	end process;
	
	--Process que actualiza las posiciones destino del 
	DESTINOS : process(CLK50)
	begin
		if (CLK50'event and CLK50 = '1') then	
			if (FRAME = '1') then
				case EDO is
					when MOVER =>
						S_HABEMUS_MELEE <= '0'; --Reinicia la bandera para cuando venimos de ATAQUE4
						S_DESTINO_X <= POS_INICIAL_X;
				
						--Cada que el timer llega a un multiplo de 30, cambia de posición destino
						if (timer mod 30 = 0) then
							S_DESTINO_Y <= TOPE_SUP + to_integer(unsigned(valorRNG(7 downto 0))); --Genera un destino aleatorio
						end if;
						
					when ATAQUE1 =>
						S_HABEMUS_MELEE <= '0';	
						S_DESTINO_X <= POS_INICIAL_X;
						if (timer mod 40 = 0) then
							S_DESTINO_Y <= TOPE_SUP + to_integer(unsigned(valorRNG(7 downto 0)));
						end if;
						
					when ATAQUE2 =>
						S_HABEMUS_MELEE <= '0';
						S_DESTINO_X <= POS_INICIAL_X;
						if (timer mod 40 = 0) then
							S_DESTINO_Y <= TOPE_SUP + to_integer(unsigned(valorRNG(7 downto 0)));
						end if;
						
					--Ataque 3 sigue a kirby, la actualizo en otro process
					
					when ATAQUE4 => --Aventarse hacia Kirby
						
						if (S_HABEMUS_MELEE = '1') then
						--Regresar a la posicion
							S_DESTINO_X <= POS_INICIAL_X;
							
						elsif (S_VILLANO_X > TOPE_IZQ + 20 and S_HABEMUS_MELEE = '0') then
						--Ir hacia la izquiera de la pantalla hacia kirby
							S_DESTINO_X <= TOPE_IZQ + 20;	
						else
						--Marcar que se llegó al límite del ataque
							S_HABEMUS_MELEE <= '1';
						end if;
						
					when others => 
						S_DESTINO_X <= POS_INICIAL_X;
						S_DESTINO_Y <= POS_INICIAL_Y;
				end case;
			end if;
		end if;
	end process;
	
	
	--Process que actualiza las posiciones del villano
	VILLANOPOS : process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1') then	
				if (FRAME = '1') then
				
					case EDO is
					
					--Quedarse en posición inicial
						when IDLE => 
							S_VILLANO_X <= POS_INICIAL_X;
							S_VILLANO_Y <= POS_INICIAL_Y;
							S_VILLANO_VX <= 0;
							S_VILLANO_VY <= 0;
							DIR_VY <= 0;
							DIR_VX <= 0;
							
					--Moverse hacia el destino calculado en el process de destinos
						when MOVER => 	
						
							S_VILLANO_VY <= 5;
							S_VILLANO_VX <= 0;
							if (S_VILLANO_Y + 5 < S_DESTINO_Y) then
								 DIR_VY <= 1;
							elsif (S_VILLANO_Y > S_DESTINO_Y + 5) then
								 DIR_VY <= -1;
							else
								DIR_VY <= 0;
							end if;
							
						when ATAQUE1 => 
						
							S_VILLANO_VY <= 5;
							S_VILLANO_VX <= 0;
							if (S_VILLANO_Y + 5 < S_DESTINO_Y) then
								 DIR_VY <= 1;
							elsif (S_VILLANO_Y > S_DESTINO_Y + 5) then
								 DIR_VY <= -1;
							else
								DIR_VY <= 0;
							end if;
							
					
						when ATAQUE2 =>
							S_VILLANO_VY <= 8;
							S_VILLANO_VX <= 0;
							if (S_VILLANO_Y + 8 < S_DESTINO_Y) then
								 DIR_VY <= 1;
							elsif (S_VILLANO_Y > S_DESTINO_Y + 8) then
								 DIR_VY <= -1;
							else
								DIR_VY <= 0;
							end if;

						when ATAQUE3 => 
						--Seguir a kirby
							S_VILLANO_VY <= 4;
							S_VILLANO_VX <= 0;
							if (S_VILLANO_Y + 8 < KIRBY_Y) then
								  DIR_VY <= 1;
							elsif (S_VILLANO_Y > KIRBY_Y + 8) then 
								  DIR_VY <= -1;
							else
								  DIR_VY <= 0;
							end if;
							
						when ATAQUE4 => --Se avienta hacia kirby y la sigue
							
							S_VILLANO_VY <= 2;
							S_VILLANO_VX <= 9;
							if (S_HABEMUS_MELEE = '0') then
								if (S_VILLANO_Y + 8 < KIRBY_Y) then
									  DIR_VY <= 1;
								elsif (S_VILLANO_Y > KIRBY_Y + 8) then 
									  DIR_VY <= -1;
								else
									  DIR_VY <= 0;
								end if;
								
							else 
								DIR_VY <= 0;
							end if;
							
							if (S_VILLANO_X + 8 < S_DESTINO_X) then
								  DIR_VX <= 1;
							elsif (S_VILLANO_X > S_DESTINO_X + 8) then 
								  DIR_VX <= -1;
							else
								  DIR_VX <= 0;
							end if;
							
						when MORIR =>
							 S_VILLANO_VX <= 0;
							 S_VILLANO_VY <= 0;
							 DIR_VY <= 0;
							 DIR_VX <= 0;
							
						when others => 
							S_VILLANO_X <= 650;
							S_VILLANO_Y <= 263;
							S_VILLANO_VX <= 0;
							S_VILLANO_VY <= 0;
							DIR_VY <= 0;
							DIR_VX <= 0;
					end case;
					
					if (DIR_VY = -1) then --Mover arriba
						S_VILLANO_Y <= S_VILLANO_Y - S_VILLANO_VY;
					elsif(DIR_VY = 1) then --Mover abajo
						S_VILLANO_Y <= S_VILLANO_Y + S_VILLANO_VY;
					end if;
					
					if (DIR_VX = -1) then --Mover izquierda
						S_VILLANO_X <= S_VILLANO_X - S_VILLANO_VX;
					elsif(DIR_VX = 1) then --Mover derecha
						S_VILLANO_X <= S_VILLANO_X + S_VILLANO_VX;
					end if;
					
				end if;
			end if;
	end process;
	
	
	--Atacar a Kirby aventando las estrellas o aventándose hacie Kirby
	ATACKONKIRBY : process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1') then	
				if (FRAME = '1') then
					case EDO is
						when IDLE => S_ATACA <= "00";
						when MOVER => S_ATACA <= "00";
						when ATAQUE1 => 
						--Ataque tipo 01 (derecho) cuando el timer de ataque es 0
							if (timer_a = 0) then
								S_ATACA <= "01";
							else
								S_ATACA <= "00";
							end if;
							
						when ATAQUE2 => 
						--Ataque tipo 10 (dirigido) cuando el timer de ataque es 0
							if (timer_a = 0) then
								S_ATACA <= "10";
							else 
								S_ATACA <= "00";
							end if;
							
						when ATAQUE3 =>
						--Manda el ataque de las 4 estrellas 
							if (timer_a = 0) then
								S_ATACA <= "11";
							else 
								S_ATACA <= "00";
							end if;
						when others => S_ATACA <= "00";
					end case;
				end if;
			end if;
	end process;
	
	--Process para actualizar la vida del villano
	VIDA : process(CLK50)
	begin
		if (CLK50'event and CLK50 = '1') then	
			if (FRAME = '1') then
				case EDO is
					when IDLE => 
						S_VIDA_V <= 10;
						
					when MORIR => Null;
						
					when others => --Estados donde se juega
						if (AUCH = '1' and timer_i = 0 and S_VIDA_V > 0) then
							S_VIDA_V <= S_VIDA_V - 1;
						end if;
				end case;
			end if;
		end if;
	end process;
	
	
	--Process que elige el sprite correcto para la situación
	SPRITERO : process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1')	then
					if (FRAME = '1') then
						case EDO is
							when MOVER | ATAQUE1 | ATAQUE2 | ATAQUE3 => 
								case S_SPRITE is
									when 0 =>
									--Cambiar al sprite de ataque cuando hay ataque
										if (s_ATACA /= "00" and timer_sprite_at = 0) then
											S_SPRITE <= 1;
										end if;
									--Cambiar al sprite normal cuando el timer del sprite del ataque acabó
									when 1 =>
										if (timer_sprite_at = 0) then
											S_SPRITE <= 0;
										end if;
								end case;
								
							
							when ATAQUE4 => 
							--En el ataque melee, pongo el sprite de ataque mientras el villano se esté aventando
										if (S_HABEMUS_MELEE = '0') then
											S_SPRITE <= 1;
										else
											S_SPRITE <= 0;
										end if;	
								
							when others => S_SPRITE <= 0;
						end case;
					end if;
			end if;
		end process;
	
	--Generar valores random para hacer que el villano sea dinámico
	RANDOM : process(CLK50)
		begin
			if (CLK50'event and CLK50 = '1') then	
				if (FRAME = '1') then
					--Manera de generar numeros random con bits.
					valorRNG <= valorRNG(14 downto 0) & (valorRNG(15) xor valorRNG(13) xor valorRNG(12) xor valorRNG(10));
				end if;
			end if;
	end process;
	
end architecture;