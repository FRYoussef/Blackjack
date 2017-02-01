library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity controller is
    port (clk, reset, start, continue, stand: in std_logic;
        loser, wrong_card: in std_logic;
        control: out std_logic_vector (6 downto 0));
end controller;

architecture ARCH of controller is

    type T_STATE is (initial, load_addr, read_from_MEM, load_card_delete_MEM, compare, 
							wrong_card_wait, update_score, right_card_wait, cargaPuntos);
							
    signal STATE, NEXT_STATE: T_STATE;
    signal control_aux: std_logic_vector (6 downto 0);
	 
    alias ld_addr: std_logic is control_aux (0);
    alias write_MEM: std_logic is control_aux (1);
    alias ld_Card: std_logic is control_aux (2);
    alias ld_Score: std_logic is control_aux (3);
    alias reset_i: std_logic is control_aux (4);
    alias ld_Points: std_logic is control_aux (5);
    alias mux_points: std_logic is control_aux (6);

begin

    control <= control_aux;

    SYNC_STATE: process (clk, reset)
    begin
	 
        if reset = '1' then
            STATE <= cargaPuntos;
        elsif clk'event and clk='1' then
	    STATE <= NEXT_STATE;
        end if;
		  
    end process SYNC_STATE;
	 
    COMB: process (STATE, start, continue, stand, loser, wrong_card)
    begin
	 
       control_aux <= (others => '0');
		 
        case STATE is
		--Estado previo para cargar los puntos de la partida
		when cargaPuntos =>
			ld_Points <= '1';
			mux_points <= '1';
			NEXT_STATE <= initial;

		--Resetear la ruta de datos
		when initial =>
			reset_i <= '1';
			if start = '0' then
				NEXT_STATE <= load_addr;
			else
				NEXT_STATE <= initial;
			end if;

		--Cargamos una carta al azar del contador
		when load_addr =>
			ld_addr <= '1';
			NEXT_STATE <= read_from_MEM;

		--Leer de la memoria la carta
		when read_from_MEM =>
			NEXT_STATE <= load_card_delete_MEM;

		--Escribir un cero en la memoria de donde se saco la carta
		when load_card_delete_MEM =>
			ld_Card <= '1';
			write_MEM <= '1';
			NEXT_STATE <= compare;

		--Vemos si la memoria ya tenia un cero para seguir
		when compare =>
			if wrong_card = '1' then
				NEXT_STATE <= wrong_card_wait;
			else
				NEXT_STATE <= update_score;
			end if;

		--Si el jugador continua volvemos a cargar carta
		when wrong_card_wait =>
			if continue = '0' then
				NEXT_STATE <= load_addr;
			else
				NEXT_STATE <= wrong_card_wait;
			end if;

		--Aumentamos la puntuacion
		when update_score =>
			ld_Score <= '1';
			NEXT_STATE <= right_card_wait;

		--Tenemos que ver si el jugador a perdido, y quiere continuar o plantarse
		when right_card_wait =>
			if continue = '0' and loser = '0' then
				NEXT_STATE <= load_addr;
			else
				if stand = '0' then
					ld_Points <= '1';
					NEXT_STATE <= initial;
				else
					NEXT_STATE <= right_card_wait;
				end if;
			end if;
				
		  end case;
    end process COMB;

end ARCH;
