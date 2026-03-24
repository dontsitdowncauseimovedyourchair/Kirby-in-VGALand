--Top Level Kirby in Papulandia

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity KIRBYINPAPULANDIA is
	port (CLK, RST, EN: in std_logic; 
			StartGame, Arriba, Abajo, Izquierda, Derecha, Ataque: in std_logic; --Inputs
			VSYNC : out std_logic; 	--Sincronía vertical al VGA
			B, G, R : out std_logic_vector(3 downto 0); --RGB al VGA
			HSYNC : out std_logic --Sincronía horizontal al VGA
			);
end entity;

architecture ARC of KIRBYINPAPULANDIA is

--Componentes del control del VGA

--Divisor de Frecuencia
component DIVFREC is
	port (CLK, RST: in std_logic;	
			F : out std_logic);
end component;

--Contador horizontal a 800
component CONTADOR800 is 
	port (CLK, RST, EN : in std_logic;
			 Cuenta : out std_logic_vector(9 downto 0);
			 Overflow : out std_logic);
end component;


--Contador Vertical a 525
component CONTADOR525 is 
	port (CLK, RST, EN : in std_logic;
			 Cuenta : out std_logic_vector(9 downto 0);
			 Overflow : out std_logic);
end component CONTADOR525;


--Para la sincronía vertical, definir el front porch, la zona visible y el back porch
component Maquinaestados1 is
	port (CLK, RST : in std_logic;
			CONTADOR525 : in std_logic_vector (9 downto 0);
			VSYNC : out std_logic;
			VSYNCEST : out std_logic_vector(1 downto 0));
end component;


--Para la sincronía vertical, definir el front porch, la zona visible y el back porch
component Maquinaestados2 is 
	port (CLK, RST : in std_logic;
			CONTADOR525 : in std_logic_vector(9 downto 0);
			CONTADOR800 : in std_logic_vector(9 downto 0);
			VSYNCEST : in std_logic_vector (1 downto 0);
			DIBUJA : out std_logic;
			HSYNC : out std_logic);
end component;


--Componentes del juego

--Máquina de estados del game engine, lógica del juego, colisiones, orquestración.
component GAME_ENGINE is
		port (	
		 CLK50 : in std_logic; 
	    SE_DIBUJO : in std_logic;
		 LOGICAR : out std_logic;  
		 StartGame: in std_logic;
		
		 ESTADOJUEGO : out std_logic_vector(1 downto 0);
		 
		 VIDA_K : in integer range 0 to 14;
		 ATAQUE_K : in std_logic;
		 VOLANDO_EK : in std_logic_vector(2 downto 0);
		
		 VIDA_V : in integer range 0 to 14;
		 ATAQUE_V : in std_logic_vector(1 downto 0);
		 VOLANDO_EV : in std_logic_vector(3 downto 0);
		
		 KIRBY_X : in integer range 0 to 799;
		 KIRBY_Y : in integer range 0 to 524;
		
		 VILLANO_X : in integer range 0 to 799;
		 VILLANO_Y : in integer range 0 to 524;
		 
		 --Estrellas de Kirby
		 ESTRELLAK1_X : in integer range 0 to 799;
		 ESTRELLAK1_Y : in integer range 0 to 524;
		 ESTRELLAK2_X : in integer range 0 to 799;
		 ESTRELLAK2_Y : in integer range 0 to 524;
		 ESTRELLAK3_X : in integer range 0 to 799;
		 ESTRELLAK3_Y : in integer range 0 to 524;
		 
		 --Posiciones iniciales
		 I_ESTRELLAK1_X : out integer range 0 to 799;
		 I_ESTRELLAK1_Y : out integer range 0 to 524;
		 I_ESTRELLAK2_X : out integer range 0 to 799;
		 I_ESTRELLAK2_Y : out integer range 0 to 524;
		 I_ESTRELLAK3_X : out integer range 0 to 799;
		 I_ESTRELLAK3_Y : out integer range 0 to 524;

		 --Estrellas del Villano
		 ESTRELLAV1_X : in integer range 0 to 799;
		 ESTRELLAV1_Y : in integer range 0 to 524;
		 ESTRELLAV2_X : in integer range 0 to 799;
		 ESTRELLAV2_Y : in integer range 0 to 524;
		 ESTRELLAV3_X : in integer range 0 to 799;
		 ESTRELLAV3_Y : in integer range 0 to 524;
		 ESTRELLAV4_X : in integer range 0 to 799;
		 ESTRELLAV4_Y : in integer range 0 to 524;
		 
		 --Posiciones iniciales
		 I_ESTRELLAV1_X : out integer range 0 to 799;
		 I_ESTRELLAV1_Y : out integer range 0 to 524;
		 I_ESTRELLAV2_X : out integer range 0 to 799;
		 I_ESTRELLAV2_Y : out integer range 0 to 524;
		 I_ESTRELLAV3_X : out integer range 0 to 799;
		 I_ESTRELLAV3_Y : out integer range 0 to 524;
		 I_ESTRELLAV4_X : out integer range 0 to 799;
		 I_ESTRELLAV4_Y : out integer range 0 to 524;
		 
		 --Velocidad inicial de las estrellas del villano
		 I_ESTRELLAV_VX : out integer range -10 to 10;
		 I_ESTRELLAV_VY : out integer range -10 to 10;
		 
		 AVENTAR_K, PUF_ESTRELLAK : out std_logic_vector(2 downto 0);
		 
		 DANO_V, DANO_K : out std_logic;
		 TIPO_ESTRELLA : out std_logic_vector(7 downto 0);
		 AVENTAR_V, PUF_ESTRELLAV, PREPARAR_V : out std_logic_vector(3 downto 0)
	);
end component;

--Renderer del juego (contiene los sprites)
component DIBUJADOR is
	port ( pixel_x, pixel_y : in integer range 0 to 1023;
			 DIBUJAR : in std_logic;		
			 
			 ESTADOJUEGO : in std_logic_vector(1 downto 0);
			
			 KIRBY_X : in integer range 0 to 799;
			 KIRBY_Y : in integer range 0 to 524;
			 
			 VIDA_K : in integer range 0 to 14;
			 VIDA_V : in integer range 0 to 14;

			 VILLANO_X : in integer range 0 to 799;
			 VILLANO_Y : in integer range 0 to 524;

			 ESTRELLAK1_X : in integer range 0 to 799;
			 ESTRELLAK1_Y : in integer range 0 to 524;
			 ESTRELLAK2_X : in integer range 0 to 799;
			 ESTRELLAK2_Y : in integer range 0 to 524;
			 ESTRELLAK3_X : in integer range 0 to 799;
			 ESTRELLAK3_Y : in integer range 0 to 524;

			 ESTRELLAV1_X : in integer range 0 to 799;
			 ESTRELLAV1_Y : in integer range 0 to 524;
			 ESTRELLAV2_X : in integer range 0 to 799;
			 ESTRELLAV2_Y : in integer range 0 to 524;
			 ESTRELLAV3_X : in integer range 0 to 799;
			 ESTRELLAV3_Y : in integer range 0 to 524;
			 ESTRELLAV4_X : in integer range 0 to 799;
			 ESTRELLAV4_Y : in integer range 0 to 524;
			 			 
			 SPRITE_K : in integer range 0 to 1;
			 SPRITE_V : in integer range 0 to 1;
						 
			 R, G, B: out std_logic_vector(3 downto 0)
			 
			 
	 );				
end component;


--Máquina de estados de Kirby
component KIRBY is 
	port (
		CLK50 : in std_logic;
		FRAME : in std_logic;
		ESTADO_JUEGO : in std_logic_vector(1 downto 0);
		Arriba, Abajo, Izquierda, Derecha : in std_logic;
		AUCH : in std_logic;
		PIU : in std_logic;
		ATAQUE : out std_logic;
		VIDA : out integer range 0 to 14;
		KIRBY_X : out integer range 0 to 799;
		KIRBY_Y : out integer range 0 TO 524;
		SPRITE : out integer range 0 to 1
	);
end component;


--Máquina de estados del antagonista	
component VILLANO is 
	port (
		CLK50 : in std_logic;
		FRAME : in std_logic;
		ESTADOJUEGO : in std_logic_vector(1 downto 0);
		
		AUCH : in std_logic;
		
		KIRBY_X : in integer range 0 to 799;
		KIRBY_Y : in integer range 0 to 524;
		
		VILLANO_X : out integer range 0 to 799;
		VILLANO_Y : out integer range 0 to 524;
		
		VIDA_V : out integer range 0 to 14;
		
		ATACA : out std_logic_vector(1 downto 0); 
		
		SPRITE : out integer range 0 to 1
	);
end component;

--Máquina de estado de Estrellas
component ESTRELLA_V is
	port (
		CLK50 : in std_logic;
		FRAME : in std_logic;
		TIPO_ESTRELLA : in std_logic;		
		TIPO_VUELO : in std_logic_vector(1 downto 0);	
		VOLAR, Preparar : in std_logic;
		PUF : in std_logic;	
		
		VOLANDO : out std_logic; 
		
		INICIO_X : in integer range 0 to 799;
		INICIO_Y : in integer range 0 to 524;
		INICIO_VX : in integer range -10 to 10;
		INICIO_VY : in integer range -10 to 10;
		
		KIRBY_Y : in integer range 0 to 524;
		
		ESTRELLAV_X : out integer range 0 to 799;
		ESTRELLAV_Y : out integer range 0 to 524
	);
end component;

--Señales entre componentes

signal Freq : std_logic;
signal CNT : std_logic_vector(9 downto 0);
signal Over : std_logic;
signal CNT2 : std_logic_vector(9 downto 0);
signal VESYNCEST : std_logic_vector(1 downto 0);

--Flow del juego
signal dibujarsiono : std_logic;
signal habemus_dibujo : std_logic;
signal estado_juego : std_logic_vector(1 downto 0);
signal S_FRAME : std_logic;

--Array de posiciones
type POS_E_X is array (0 to 3) of integer range 0 to 799;
type POS_E_Y is array (0 to 3) of integer range 0 to 524;

--Señales entre gey engine y dibujador

signal S_KIRBY_X : integer range 0 to 799;
signal S_KIRBY_Y : integer range 0 to 524;

--Señales de Kirby
signal S_VIDA_K : integer range 0 to 14;
signal S_DANO_K : std_logic;
signal S_ATAQUE_K : std_logic;

signal S_VILLANO_X : integer range 0 to 799;
signal S_VILLANO_Y : integer range 0 to 524;

signal S_ESTRELLAK_X : POS_E_X;
signal S_ESTRELLAK_Y : POS_E_Y;

signal S_ESTRELLAV_X : POS_E_X;
signal S_ESTRELLAV_Y : POS_E_Y;

--Velocidades iniciales de las estrellas
signal S_I_VEL_EX : integer range -10 to 10;
signal S_I_VEL_EY : integer range -10 to 10;

--Acciones del villano
signal S_VIDA_VILLANO: integer range 0 to 14;
signal S_DANO_V : std_logic;
signal S_ATAQUE_V: std_logic_vector(1 downto 0);


--Acciones de la estrella del villano
signal S_VOLANDO_EV, S_AVENTAR_V, S_PUF_ESTRELLAV, S_PREPARAR_EV : std_logic_vector(3 downto 0);
signal S_TIPO_VUELO : std_logic_vector(7 downto 0);
signal S_I_ESTRELLAV_X : POS_E_X;
signal S_I_ESTRELLAV_Y : POS_E_Y;

--Acciones de la estrellas de kirby
signal S_VOLANDO_EK, S_AVENTAR_K, S_PUF_ESTRELLAK : std_logic_vector(2 downto 0);
signal S_I_ESTRELLAK_X : POS_E_X;
signal S_I_ESTRELLAK_Y : POS_E_Y;


--Sprites
signal S_SPRITE_K : integer range 0 to 1;
signal S_SPRITE_V : integer range 0 to 1;

	
begin 

--Interconexiones entre componentes.

I1 : DIVFREC port map (CLK, RST, Freq);
I2 : CONTADOR800 port map (Freq, RST, EN, CNT, Over);
I3 : CONTADOR525 port map (Freq, RST, Over, CNT2, habemus_dibujo);
I4 : Maquinaestados1 port map (Freq, RST, CNT2, VSYNC, VESYNCEST);
I5 : Maquinaestados2 port map (Freq, RST, CNT2, CNT, VESYNCEST, dibujarsiono, HSYNC);

I6 : GAME_ENGINE port map(
									CLK, habemus_dibujo, S_FRAME, StartGame, estado_juego, S_VIDA_K, S_ATAQUE_K, S_VOLANDO_EK, S_VIDA_VILLANO, S_ATAQUE_V, S_VOLANDO_EV, S_KIRBY_X, S_KIRBY_Y, S_VILLANO_X, S_VILLANO_Y, 
									S_ESTRELLAK_X(0), S_ESTRELLAK_Y(0), S_ESTRELLAK_X(1), S_ESTRELLAK_Y(1), S_ESTRELLAK_X(2), S_ESTRELLAK_Y(2), 
									S_I_ESTRELLAK_X(0), S_I_ESTRELLAK_Y(0), S_I_ESTRELLAK_X(1), S_I_ESTRELLAK_Y(1), S_I_ESTRELLAK_X(2), S_I_ESTRELLAK_Y(2), 
									S_ESTRELLAV_X(0), S_ESTRELLAV_Y(0), S_ESTRELLAV_X(1), S_ESTRELLAV_Y(1), S_ESTRELLAV_X(2), S_ESTRELLAV_Y(2), S_ESTRELLAV_X(3), S_ESTRELLAV_Y(3), 
									S_I_ESTRELLAV_X(0), S_I_ESTRELLAV_Y(0), S_I_ESTRELLAV_X(1), S_I_ESTRELLAV_Y(1), S_I_ESTRELLAV_X(2), S_I_ESTRELLAV_Y(2), S_I_ESTRELLAV_X(3), S_I_ESTRELLAV_Y(3),
									S_I_VEL_EX, S_I_VEL_EY,
									S_AVENTAR_K, S_PUF_ESTRELLAK,
									S_DANO_V, S_DANO_K, S_TIPO_VUELO, S_AVENTAR_V, S_PUF_ESTRELLAV, S_PREPARAR_EV
								 );
V  : VILLANO port map(CLK, S_FRAME, estado_juego, S_DANO_V, S_KIRBY_X, S_KIRBY_Y, S_VILLANO_X, S_VILLANO_Y, S_VIDA_VILLANO, S_ATAQUE_V, S_SPRITE_V);
K  : KIRBY port map(CLK, S_FRAME, estado_juego, Arriba, Abajo, Izquierda, Derecha, S_DANO_K, ATAQUE, S_ATAQUE_K, S_VIDA_K, S_KIRBY_X, S_KIRBY_Y, S_SPRITE_K);

--Instanciación de 4 Estrellas para el Villano
EV1: ESTRELLA_V port map(CLK, S_FRAME, '1', S_TIPO_VUELO(1 downto 0), S_AVENTAR_V(0), S_PREPARAR_EV(0), S_PUF_ESTRELLAV(0), S_VOLANDO_EV(0), S_I_ESTRELLAV_X(0), S_I_ESTRELLAV_Y(0), S_I_VEL_EX, S_I_VEL_EY, S_KIRBY_Y, S_ESTRELLAV_X(0), S_ESTRELLAV_Y(0));
EV2: ESTRELLA_V port map(CLK, S_FRAME, '1', S_TIPO_VUELO(3 downto 2), S_AVENTAR_V(1), S_PREPARAR_EV(1), S_PUF_ESTRELLAV(1), S_VOLANDO_EV(1), S_I_ESTRELLAV_X(1), S_I_ESTRELLAV_Y(1), S_I_VEL_EX, S_I_VEL_EY, S_KIRBY_Y, S_ESTRELLAV_X(1), S_ESTRELLAV_Y(1));
EV3: ESTRELLA_V port map(CLK, S_FRAME, '1', S_TIPO_VUELO(5 downto 4), S_AVENTAR_V(2), S_PREPARAR_EV(2), S_PUF_ESTRELLAV(2), S_VOLANDO_EV(2), S_I_ESTRELLAV_X(2), S_I_ESTRELLAV_Y(2), S_I_VEL_EX, S_I_VEL_EY, S_KIRBY_Y, S_ESTRELLAV_X(2), S_ESTRELLAV_Y(2));
EV4: ESTRELLA_V port map(CLK, S_FRAME, '1', S_TIPO_VUELO(7 downto 6), S_AVENTAR_V(3), S_PREPARAR_EV(3), S_PUF_ESTRELLAV(3), S_VOLANDO_EV(3), S_I_ESTRELLAV_X(3), S_I_ESTRELLAV_Y(3), S_I_VEL_EX, S_I_VEL_EY, S_KIRBY_Y, S_ESTRELLAV_X(3), S_ESTRELLAV_Y(3));

--Instanciación de 3 Estrellas para Kirby
EK1 : ESTRELLA_V port map(CLK, S_FRAME, '0', "00", S_AVENTAR_K(0), '0', S_PUF_ESTRELLAK(0), S_VOLANDO_EK(0), S_I_ESTRELLAK_X(0), S_I_ESTRELLAK_Y(0), 8, 0, S_KIRBY_Y, S_ESTRELLAK_X(0), S_ESTRELLAK_Y(0));
EK2 : ESTRELLA_V port map(CLK, S_FRAME, '0', "00", S_AVENTAR_K(1), '0', S_PUF_ESTRELLAK(1), S_VOLANDO_EK(1), S_I_ESTRELLAK_X(1), S_I_ESTRELLAK_Y(1), 8, 0, S_KIRBY_Y, S_ESTRELLAK_X(1), S_ESTRELLAK_Y(1));
EK3 : ESTRELLA_V port map(CLK, S_FRAME, '0', "00", S_AVENTAR_K(2), '0', S_PUF_ESTRELLAK(2), S_VOLANDO_EK(2), S_I_ESTRELLAK_X(2), S_I_ESTRELLAK_Y(2), 8, 0, S_KIRBY_Y, S_ESTRELLAK_X(2), S_ESTRELLAK_Y(2));

I7 : DIBUJADOR port map(to_integer(unsigned(CNT)), to_integer(unsigned(CNT2)), dibujarsiono, estado_juego, 
								S_KIRBY_X, S_KIRBY_Y, S_VIDA_K, S_VIDA_VILLANO, S_VILLANO_X, S_VILLANO_Y,
								S_ESTRELLAK_X(0), S_ESTRELLAK_Y(0), S_ESTRELLAK_X(1), S_ESTRELLAK_Y(1), S_ESTRELLAK_X(2), S_ESTRELLAK_Y(2),
								S_ESTRELLAV_X(0), S_ESTRELLAV_Y(0), S_ESTRELLAV_X(1), S_ESTRELLAV_Y(1), S_ESTRELLAV_X(2), S_ESTRELLAV_Y(2), S_ESTRELLAV_X(3), S_ESTRELLAV_Y(3), 
								S_SPRITE_K, S_SPRITE_V,
								R, G, B
							);

end ARC;
