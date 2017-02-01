library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity datapath is
    port (clk_quick, clk_slow, reset: in std_logic;
         control: in std_logic_vector (6 downto 0);
			points: out std_logic_vector (3 downto 0);
         loser, wrong_card: out std_logic;
         card, score1, score2: out std_logic_vector (6 downto 0));
end datapath;

architecture ARCH of datapath is

   component ram_memory is
		generic (M: natural:=6; N: natural:=4);
		port (clk,we: in std_logic;
				addr: in std_logic_vector (M-1 downto 0);
				di: in std_logic_vector (N-1 downto 0);
				do: out std_logic_vector (N-1 downto 0));
	end component;
	
	component register_n is
		generic (n: integer := 8);
		port (clk, reset, load: in std_logic; 
				D: in std_logic_vector(n-1 downto 0);
				Q: out std_logic_vector(n-1 downto 0));
	end component;
	
	component counter is
		port (clk, reset, count: in std_logic;
					output: out std_logic_vector (5 downto 0));
	end component;
	
	component bin2display2 is
		port ( x : in  STD_LOGIC_VECTOR (4 downto 0);
				  display1, display2 : out  STD_LOGIC_VECTOR (6 downto 0));
	end component;
	
	component bin2display1 is
		 Port ( x : in  STD_LOGIC_VECTOR (3 downto 0);
				  display : out  STD_LOGIC_VECTOR (6 downto 0));
	end component;
	
	

    signal control_aux: std_logic_vector(6 downto 0);
	 
    alias ld_addr: std_logic is control_aux (0);
    alias write_MEM: std_logic is control_aux (1);
    alias ld_Card: std_logic is control_aux (2);
    alias ld_Score: std_logic is control_aux (3);
    alias reset_i: std_logic is control_aux (4);
	 alias ld_Points: std_logic is control_aux (5);
	 alias mux_points: std_logic is control_aux (6);

    signal final_reset, loser_aux, wrong_card_aux: std_logic;
	 signal reg_counter, reg_addr: std_logic_vector (5 downto 0) := (others => '0');
	 signal mem_out, reg_card, suma_points, reg_points, aux_points: std_logic_vector (3 downto 0) := (others => '0');
	 signal aux_card, aux_score1, aux_score2: std_logic_vector (6 downto 0) := (others => '0');
	 signal suma, reg_score: std_logic_vector (4 downto 0) := (others => '0');
	 signal A,B: std_logic_vector(3 downto 0);
    

begin 

    control_aux <= control;
    final_reset <= reset_i OR reset;
	 card <= aux_card;
	 score1 <= aux_score1;
	 score2 <= aux_score2;
	 points <= reg_points;
   

    loser <= loser_aux;
    wrong_card <= wrong_card_aux;
	 
	 --Contador
	 counter_card: counter port map(clk_quick, '0', '1', reg_counter);
	 
	 --Registro direccion
	 Raddr: register_n generic map (6) port map(clk_slow, final_reset, ld_addr, reg_counter, reg_addr);
	 
	 --Memoria Ram
	 ram: ram_memory port map(clk_slow, write_MEM, reg_addr, "0000", mem_out);
	 
	 --Registro carta
	 Rcard: register_n generic map (4) port map(clk_slow, final_reset, ld_Card, mem_out, reg_card);
	 
	 --Comparador carta incorrecta
	 wrong_card_aux <= '1' when reg_card = "0000" else '0';
	 
	 --Display de la carta
	 cardDisplay: bin2display1 port map(reg_card, aux_card);
	 
	 --Sumador
	 suma <= std_logic_vector(unsigned('0' & reg_card) + unsigned(reg_score));
	 
	 --Puntuacion
	 Rscore: register_n generic map (5) port map(clk_slow, final_reset, ld_Score, suma, reg_score);
	 
	 --Comparador de Puntuacion
	 loser_aux <= '1' when (to_integer(unsigned(reg_score))) > 21 else '0';
	 
	 --Display de la puntuacion
	 scoreDisplay: bin2display2 port map(reg_score, aux_score1, aux_score2);
	 
	 --Sumador Restador de los puntos
	 A <= std_logic_vector(unsigned(reg_points) + 1);
	 B <= std_logic_vector(unsigned(reg_points) - 1);
	 suma_points <= A when (to_integer(unsigned(reg_score))) >= 18 and (to_integer(unsigned(reg_score))) < 22
						else B;
	 
	 --Multiplexor para inicializar el registro
	 aux_points <= suma_points when mux_points = '0' else "1010";
	 
	 --Puntuacion
	 RPoints: register_n generic map (4) port map(clk_slow, reset, ld_Points, aux_points, reg_points);
	 
	 
end ARCH;
