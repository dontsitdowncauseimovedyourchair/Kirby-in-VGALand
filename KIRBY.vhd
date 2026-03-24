--Kirby - Kirby in Papulandia

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity KIRBY is 
	port (
		CLK50 : in std_logic;
		FRAME : in std_logic;
		ESTADO_JUEGO : in std_logic_vector(1 downto 0);		--estado del game engine
		Arriba, Abajo, Izquierda, Derecha : in std_logic;	--Inputs del jugador
		AUCH : in std_logic;		--Daño a kirby
		PIU : in std_logic;		--Input del jugador de disparar
		ATAQUE : out std_logic;	--Output de disparar hacia el game engine
		VIDA : out integer range 0 to 14;	--Vida de kirby (tiene 3 por ahora)
		KIRBY_X : out integer range 0 to 799;	--Posición x de kirby
		KIRBY_Y : out integer range 0 TO 524;	--Posición y de kirby
		SPRITE : out integer range 0 to 1		--Sprite a mostrar
	);
end entity;

architecture ARC of KIRBY is

	--Estados de Kirby
	type KIRBYESTADOS is (IDLE, VIVO, NO_VIVO);
	signal EDO, EDO_F : KIRBYESTADOS := IDLE;
	
	constant TOPE_IZQ : integer := 143 - 32; --Tope izquierdo menos el ancho del sprite;
	constant TOPE_DER : integer := 783;
	constant TOPE_SUP : integer := 34;
	constant TOPE_INF : integer := 514 - 32; --Tope inferior menos el alto del sprite;
	
	
	--Límites de a dónde puede ir Kirby
	constant MAX_MOV_DER : integer := TOPE_DER - 200;
	constant MIN_MOV_IZQ : integer := TOPE_IZQ + 20;
	constant MAX_MOC_ARR : integer := TOPE_SUP + 30;
	constant MIN_MOV_ABJ : integer := TOPE_INF - 30;
	
	--Señales a usar en los process
	
	signal S_KIRBY_X : integer range 0 to 799 := 200;
	signal S_KIRBY_Y : integer range 0 to 524 := 263;
	
	signal DIR_X : integer range -10 to 10;
	signal DIR_Y : integer range -10 to 10;
	
	signal S_VIDA : integer range 0 to 14 := 3;
	signal S_SPRITE : integer range 0 to 1;

	
	--Timer entre ataques
	signal timer_ataque : integer range 0 to 127; 
	--Timer de invencibilidad
	signal timer_i : integer range 0 to 127;
	
	--Timer del sprite para mostrar el ataque
	signal timer_sprite_at : integer range 0 to 127;
	
	begin
	
		KIRBY_X <= S_KIRBY_X;
		KIRBY_Y <= S_KIRBY_Y;
		VIDA <= S_VIDA;
		SPRITE <= S_SPRITE;
	
		--Actualizador de timers y del estado
		FLIFLO: process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1')	then
				if (FRAME = '1') then
					EDO <= EDO_F;
					
					--Timer de ataque válido
					if (timer_ataque > 0) then
						timer_ataque <= timer_ataque - 1;
					elsif (PIU = '0' and timer_ataque = 0) then
						timer_ataque <= 60;
					end if;
					
					--Timer de invencibilidad cuando Kirby recibe daño
					if (timer_i > 0) then
						timer_i <= timer_i - 1;
					elsif(AUCH = '1' and timer_i = 0) then
						timer_i <= 30;
					end if;
					
					--Timer del sprite
					if (timer_sprite_at > 0) then
						timer_sprite_at <= timer_sprite_at - 1;
					elsif(PIU = '0') then
						timer_sprite_at <= 7;
					end if;
				end if;
			end if;
		end process;	
		
		EDOOO: process(EDO, ESTADO_JUEGO, S_VIDA) 
    begin
        -- Defaults
        EDO_F <= EDO;
        
        case ESTADO_JUEGO is
            when "00" => EDO_F <= IDLE;
            when "01" => 
                if (S_VIDA = 0) then
					 --Murió
                    EDO_F <= NO_VIVO;
                else
                    EDO_F <= VIVO;
                end if;
            when "10" => EDO_F <= NO_VIVO;
            when others => NULL;
        end case;
    end process;
		
	--Actualizar la posición de Kirby
		KIRBYPOS : process(CLK50) 
			begin
		
			if (CLK50'event and CLK50 = '1')	then
				if (FRAME = '1') then
				
					case EDO is
						when IDLE => 
							S_KIRBY_X <= 200;
							S_KIRBY_Y <= 263;
							DIR_X <= 0;
							DIR_Y <= 0;
					
						when VIVO =>
						--Movimiento con el joystick, respeta los límites establecidos
							if (arriba = '1' and S_KIRBY_Y > TOPE_SUP + 6) then
								DIR_Y <= -5;
							elsif (abajo = '1' and S_KIRBY_Y + 6 < TOPE_INF) then
								DIR_Y <= 5;
							else
								DIR_Y <= 0;
							end if;
							
							if (izquierda = '1' and S_KIRBY_X > MIN_MOV_IZQ) then
								DIR_X <= -5;
							elsif (derecha = '1' and S_KIRBY_X < MAX_MOV_DER) then
								DIR_X <= 5;
							else
								DIR_X <= 0;
							end if;
							
							
							S_KIRBY_X <= S_KIRBY_X + DIR_X;
							S_KIRBY_Y <= S_KIRBY_Y + DIR_Y;
								
						when NO_VIVO => 
							DIR_X <= 0;
							DIR_Y <= 0;
						
						when others => Null;
					end case;
					
				end if;
			end if;
		end process;
			
			
		--Disparar estrella
		PIUPIU : process(CLK50) 
			begin
				if (CLK50'event and CLK50 = '1')	then
					if (FRAME = '1') then
						case EDO is
							when IDLE => ATAQUE <= '0';
							
							when VIVO => 
							--Dispara cuando el timer está en 0, evita que el jugador pueda espamear
								if (PIU = '0' and timer_ataque = 0) then
									ATAQUE <= '1';
								else 
									ATAQUE <= '0';
								end if;
							when NO_VIVO => ATAQUE <= '0';
							when others => ATAQUE <= '0';
						end case;
					end if;
				end if;
		end process;
		
		--Daño a Kirby
		DANO : process(CLK50)
			begin
				if (CLK50'event and CLK50 = '1')	then
					if (FRAME = '1') then
						case EDO is
							when IDLE =>
								S_VIDA <= 3;
								
							when VIVO =>
								if (AUCH = '1' and timer_i = 0) then
									S_VIDA <= S_VIDA - 1;
								end if;
							when others => null;
						end case;
					end if;
				end if;
		end process;
		
		--Cambio de sprites
		SPRITERO : process(CLK50) 
		begin
			if (CLK50'event and CLK50 = '1')	then
					if (FRAME = '1') then
						case EDO is
							when VIVO => 
								case S_SPRITE is
									when 0 =>
									--Ir a sprite de ataque cuando se haga PIU y el timer del sprite esté listo
										if (PIU = '0' and timer_sprite_at = 0) then
											S_SPRITE <= 1;
										end if;
									when 1 =>
										if (timer_sprite_at = 0) then
											S_SPRITE <= 0;
										end if;
								end case;
								
							when others => S_SPRITE <= 0;
						end case;
					end if;
			end if;
		end process;
		
end architecture;