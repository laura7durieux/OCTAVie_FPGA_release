library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--- déclaration de l'entité
entity memory is
	port(clk,sop,clr : in std_logic;
		sop_out,sotrame : out std_logic;							-- attention ce n'est pas le début de la frame mais le début de la donnée (une valeur de 12 bits)
		data_in : in std_logic_vector(11 downto 0);
		data_out : out std_logic_vector(11 downto 0)
		); 
end memory;

ARCHITECTURE memory_beh of memory is

    type MEMO is array (0 to 255) of std_logic_vector(11 downto 0);
    signal mem : MEMO;
	 signal last_sop : std_logic :='0';
    


begin
readwrite : process(clk)
variable count_clk : integer range 0 to 3 :=0;
variable read_address, write_address : integer range 0 to 256 := 0;

begin
if(clr = '0') then -- logique négative - vide la mémoire
	--- For i 0-255 Mem <= others=>'0';
	for i in 0 to 255 loop
		mem(i) <= (Others =>'0');
	end loop;
	write_address := 0;
	read_address := 0;

elsif(clk'event and clk='1') then
	-- signal sop start the writing and reading
	if ((sop = '1')and(last_sop='0')) then
		count_clk := 1;
		write_address := 0;
		read_address := 0;
		sop_out <= '1'; -- to indicate that the data start to be sent 
	else 
		sop_out<='0';
	end if;
	last_sop <= sop;
		
	if ((count_clk = 1)or(count_clk = 2))and(write_address<256) then	
		-- writing mem
		mem(write_address)<= data_in;
		write_address := write_address+1;
	end if;

	if (count_clk = 2) then
		-- reading memory only 1 on 2 clock fronts
		-- at the start the memory is not written with the first data
		if(read_address=0) then 
			data_out <= data_in;
			read_address := read_address+1;
		else
			data_out <= mem(read_address);
			read_address := read_address+1;
		end if;
		sotrame <= '1';
	else
		sotrame <= '0';
	end if;

	if (count_clk = 2) then 
		count_clk := 1;
	elsif (count_clk = 1) then
		count_clk := count_clk +1;
	end if;
	
	-- Si 512 count d'horloge sont passée - 2*256- alors on se remet a l'état initiale
	if (read_address = 256) then -- modifié !
		count_clk := 0;
	end if;

end if;
end process;
end architecture;