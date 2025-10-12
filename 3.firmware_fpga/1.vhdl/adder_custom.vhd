library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;

--- déclaration de l'entité
entity adder_custom is

	port(A,B : in std_logic_vector(23 downto 0);
		S : out std_logic_vector(23 downto 0)
		); 
	
end adder_custom;

ARCHITECTURE adder_custom_beh of adder_custom is
begin

S <= A + B;

end adder_custom_beh;