library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


--- déclaration de l'entité
entity bit_select is

	port(datain : in std_logic_vector(23 downto 0);
		BPmoins, BPplus, clk : in std_logic;
		dataout : out std_logic_vector(11 downto 0)
		); 
	
end bit_select;

ARCHITECTURE bit_select_beh of bit_select is
begin
PROCESS(clk)
variable BPmoins_current : std_logic := '0';
variable BPmoins_last : std_logic := '0';

variable BPplus_current : std_logic := '0';
variable BPplus_last : std_logic := '0';

variable index : integer range 0 to 12 := 0;

BEGIN


--
IF((clk'event) and (clk = '1')) THEN
	-- Update our variable (note : buttons are logic negative - which lead to the use of not)
	BPmoins_last := BPmoins_current;
	BPmoins_current := not(BPmoins);

	BPplus_last := BPplus_current;
	BPplus_current := not(BPplus);

	-- detection de l'activation des boutons
	if((BPmoins_last='0')and(BPmoins_current='1'))then
		if(index = 0) then
			index := 0;
		else
			index := index - 1;
		end if;
	
	elsif ((BPplus_last='0')and(BPplus_current='1'))then
		if(index=12) then
			index := 12;
		else
			index := index+1;
		end if;
	
	end if;
	
	-- Attribution des bits de sortie
	dataout<= datain((index+11) downto (index));

END IF;

END PROCESS;

END ARCHITECTURE;