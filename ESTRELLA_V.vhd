--Estrellas - Kirby in Papulandia


library IEEE;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

entity ESTRELLA_V is
	port (
		CLK50 : in std_logic;
		FRAME : in std_logic;
		TIPO_ESTRELLA : in std_logic;		--0: Kirby , 1: Boss
		TIPO_VUELO : in std_logic_vector(1 downto 0);	--Por ejemplo si va derecha o va dirigida
		VOLAR, Preparar : in std_logic; --Ser aventada o preparar la estrella.
		PUF : in std_logic;	--Se pegó
		
		VOLANDO : out std_logic; --Para que el engine sepa que ya va volando y eliga otra para aventar
		
		--Posiciones iniciales
		INICIO_X : in integer range 0 to 799;
		INICIO_Y : in integer range 0 to 524;
		--Velocidades iniciales
		INICIO_VX : in integer range -10 to 10;
		INICIO_VY : in integer range -10 to 10;
		
		--Posición y de Kirby
		KIRBY_Y : in integer range 0 to 524;
		
		--Posiciones de las estrellas
		ESTRELLAV_X : out integer range 0 to 799;
		ESTRELLAV_Y : out integer range 0 to 524
	);
end entity;

architecture ARC of ESTRELLA_V is

	--Estados de las estrellas (En espera, posicionada antes de ser aventada, volando, y estrellada)
    type ESTRELLA_ESTADOS is (ESPERANDO, EN_POSICION, VOLADOR, PUFFF);
    signal EDO, EDO_F : ESTRELLA_ESTADOS := ESPERANDO;
	 
	 
	 --Altura y Anchura
	 constant ESTRELLA_W : integer := 16;
	 constant ESTRELLA_H : integer := 16;
    
	 --Límites de donde las estrellas cuentan como volando
    constant TOPE_IZQ : integer := 143 - 16; 
    constant TOPE_DER : integer := 783;
    constant TOPE_SUP : integer := 10;
    constant TOPE_INF : integer := 524; 
    

	 --Señales para uso en los process
	 
    signal S_ESTRELLAV_X : integer range 0 to 799 := 0;
    signal S_ESTRELLAV_Y : integer range 0 to 524 := 0;
	 
	 signal S_TIPO_PERMANENTE : std_logic_vector(1 downto 0);
	 
    signal VEL_X : integer range -10 to 10 := 0;
    signal VEL_Y : integer range -10 to 10 := 0;
    
    begin
    
    ESTRELLAV_X <= S_ESTRELLAV_X;
    ESTRELLAV_Y <= S_ESTRELLAV_Y;
    
    VOLANDO <= '0' when (EDO = ESPERANDO) else '1';
    
    CLOCK : process(CLK50) 
    begin
        if (CLK50'event and CLK50 = '1') then
            if (FRAME = '1') then
                EDO <= EDO_F;
            end if;
        end if;
    end process;
    
   
    EDOOO : process(EDO, VOLAR, PUF, S_ESTRELLAV_X, S_ESTRELLAV_Y)
    begin
        -- Default
        EDO_F <= EDO;
        
        case EDO is
            when ESPERANDO => --Estado fuera de la pantalla
                if (VOLAR = '1') then 
                    EDO_F <= VOLADOR; --Se le indicó que vuele de una 
					  elsif (Preparar = '1') then
						  EDO_F <= EN_POSICION;	--Se le indicó que esté en posición 
					  else
						  EDO_F <= ESPERANDO;
                end if;
					 
				 --Estado para tener las estrellas en posición en la pantalla de manera amenazante
				 when EN_POSICION =>
					if (VOLAR = '1') then
					--Volar
						EDO_F <= VOLADOR;
					elsif (PUF = '1') then
					--Hacer puff
						EDO_F <= PUFFF;
					end if;
                
            when VOLADOR =>
                if (PUF = '1') then
					 --PUFFF cuando el game engine lo indica (colisionó)
                    EDO_F <= PUFFF;
                elsif (S_ESTRELLAV_X > TOPE_DER or S_ESTRELLAV_X < TOPE_IZQ 
                       or S_ESTRELLAV_Y < TOPE_SUP or S_ESTRELLAV_Y > TOPE_INF) then
					 --Hace puf cuando se sale del área de juego
                    EDO_F <= PUFFF;
                end if;
                
            when PUFFF =>
                EDO_F <= ESPERANDO;
                
            when others =>
                EDO_F <= ESPERANDO;
        end case;
    end process;
    
	 
	 --Posición
    POSTRELLA : process(CLK50) 
    begin
        if (CLK50'event and CLK50 = '1') then
            if (FRAME = '1') then
                case EDO is
                    when ESPERANDO =>
                        S_ESTRELLAV_X <= 0; --No salen en la pantalla en modo espera
                        S_ESTRELLAV_Y <= 0;
                        
								--Aventarse directamente
                        if (VOLAR = '1') then 
                            S_ESTRELLAV_X <= INICIO_X;
                            S_ESTRELLAV_Y <= INICIO_Y;
									 S_TIPO_PERMANENTE <= TIPO_VUELO;
                            
                            if (TIPO_ESTRELLA = '1') then -- Estrella Boss              
                                VEL_X <= INICIO_VX;
                                VEL_Y <= INICIO_VY; 
                            else    -- Estrella Kirby 
                                VEL_X <= 8;
                                VEL_Y <= 0;
                            end if;
									 
								 elsif (Preparar = '1') then --Guarda la posición
                            S_ESTRELLAV_X <= INICIO_X;
                            S_ESTRELLAV_Y <= INICIO_Y;
                            S_TIPO_PERMANENTE <= TIPO_VUELO;
                         end if;
                        
								
							--Espera hasta que se le indica que debe volar	
							when EN_POSICION =>
								S_ESTRELLAV_X <= INICIO_X; 
								S_ESTRELLAV_Y <= INICIO_Y;
                        VEL_X <= 0;
							   VEL_Y <= 0; 
								
								if (VOLAR = '1') then 
									if (TIPO_ESTRELLA = '1') then -- Estrella Boss              
                                VEL_X <= INICIO_VX;
                                VEL_Y <= INICIO_VY; 
                            else    -- Estrella Kirby 
                                VEL_X <= 8;
                                VEL_Y <= 0;
                            end if;
								end if;
							  
                    when VOLADOR =>
                        
								--Caso cuando es dirigida la estrella
                        if (TIPO_ESTRELLA = '1' and S_TIPO_PERMANENTE = "01") then --Tipo dirigido
                            if (S_ESTRELLAV_Y > KIRBY_Y + 8) then 
                                 VEL_Y <= -3;
                            elsif (S_ESTRELLAV_Y + 8 < KIRBY_Y) then
                                 VEL_Y <= 3;
                            else
                                 VEL_Y <= 0;
                            end if;
								else
									VEL_Y <= 0;
                        end if;
								
                        
                        S_ESTRELLAV_X <= S_ESTRELLAV_X + VEL_X;
                        S_ESTRELLAV_Y <= S_ESTRELLAV_Y + VEL_Y;

                    when PUFFF =>
                        S_ESTRELLAV_X <= 0;
                        S_ESTRELLAV_Y <= 0;
                        VEL_X <= 0;
                        VEL_Y <= 0;
								S_TIPO_PERMANENTE <= "00";
								
                        
                    when others => null;
                end case;
                
            end if;
        end if;
    end process;
    
end architecture;