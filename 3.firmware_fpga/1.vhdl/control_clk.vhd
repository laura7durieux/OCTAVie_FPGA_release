library ieee;
use ieee.std_logic_1164.all;

------------------------------------------------------------
---------- Control Horloge ---------------------------------
------------------------------------------------------------


--- déclaration de l'entité
entity control_clk is
	generic(divider : integer := 125);
	port(CLK, rst: in std_logic; -- Clock general - 50MHz
		clk_divided : out std_logic -- Clk diviseur
		); 
	
end control_clk;


ARCHITECTURE control_clk_beh of control_clk is

signal internal_clk : std_logic :='0';

BEGIN

PROCESS (CLK, rst)

variable counter : integer range 0 to divider := 0;

BEGIN

IF((CLK'event) and (CLK = '1')) THEN
-- Reset synchrone - RST logique négative
IF (rst = '0') THEN 
	counter := 0;
	internal_clk <= '0';
ELSE
		-- Division de l'horloge 
	IF (counter=divider) THEN
		internal_clk <= not internal_clk;
		counter := 0;
	ELSE 
		counter := counter+1;
	END IF;
	

END IF;
END IF;

END PROCESS;


clk_divided <= internal_clk;

END ARCHITECTURE;