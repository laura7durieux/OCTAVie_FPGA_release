library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--- déclaration de l'entité
entity substraction_custom is

	port(clk : in std_logic;
		data_paral_ch1, data_paral_ch2 : in std_logic_vector(11 downto 0);
		data_paral : out std_logic_vector(11 downto 0)
		); 
	
end substraction_custom;

architecture substraction_custom_beh of substraction_custom is
begin

    process (clk)
        variable data : signed(12 downto 0);
    begin
        if rising_edge(clk) then
				-- the the complementing on the second chanel
				--data := not(data_paral_ch2);
				--data := data+1;
            -- Perform subtraction with proper signed resizing
            data := resize(signed(data_paral_ch1) - signed(data_paral_ch2), 13);
            -- Assign the result to the output, ensuring the correct size
            data_paral <= std_logic_vector(data(11 downto 0)); --data_paral_ch1 + data;
        end if;
    end process;

end architecture;