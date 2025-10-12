-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---------- USART	-----------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.all;


------------------------------------------

ENTITY USART_2f IS
PORT(RaS, clk, StartTr, sop : in std_logic;
     DataIN : in std_logic_vector (11 downto 0);
     TxD : out std_logic);

END USART_2f;

-------------------------------------------

ARCHITECTURE USART_2f_beh OF USART_2f IS

BEGIN

-- Creation de la trame USART
PROCESS(clk)
VARIABLE count_bits : integer range 0 to 29 := 0;  -- on envoi 30 bits
VARIABLE startTr_lastVal : std_logic := '0';  
VARIABLE sop_lastVal : std_logic := '0'; 
VARIABLE sop_ind : std_logic := '0'; 


BEGIN



	if(clk'event and clk='1') then
	
		-- initialisation avec RaS
		if(RaS = '0') then 
			count_bits := 0;
			TxD <= '1'; -- Put the ligne at rest
		
		else -- si sop alors il faut l'indiquer dans l'usart
			if(sop = '1' and sop_lastVal = '0') then
				sop_ind := '1';
			end if;
			
			
				-- mettre à 1 le comteur pour démarrer la trame - permet de synchroniser sur le changement 
				-- de valeur du processus precedant - garantit une valeur constante dans l'USART
			if(StartTr = '1' and startTr_lastVal = '0') then
				count_bits := 1;
			end if;
				
				-- First trame of data
				if(count_bits = 1) then
					TxD <= '0';							-- bit start first trame
					
				elsif(count_bits = 2) then 		-- MSB first
					TxD <= DataIN(0);				
				
				elsif(count_bits = 3) then
					TxD <= DataIN(1);
					
				elsif(count_bits = 4) then
					TxD <= DataIN(2);
					
				elsif(count_bits = 5) then
					TxD <= DataIN(3);	
				
				elsif(count_bits = 6) then
					TxD <= DataIN(4);	
				
				elsif(count_bits = 7) then
					TxD <= DataIN(5);		
				
				elsif(count_bits = 8) then
					if(sop_ind = '1') then
						TxD <= '1';
					else
						TxD <= '0';
					end if;				
				
				elsif(count_bits = 9) then
					if(sop_ind = '1') then
						TxD <= '1';
					else
						TxD <= '0';
					end if;				
				
				elsif(count_bits = 10) then
					TxD <= '1'; 						-- stop bit first trame

					
				-- Second trame of data
				elsif(count_bits = 17) then
					TxD <= '0';							-- bit start second trame
					
				elsif(count_bits = 18) then
					TxD <= DataIN(6);			-- Start MSB second trame
				
				elsif(count_bits = 19) then
					TxD <= DataIN(7);
					
				elsif(count_bits = 20) then
					TxD <= DataIN(8);
					
				elsif(count_bits = 21) then
					TxD <= DataIN(9);
				
				elsif(count_bits = 22) then		-- The 4 bits not usefull are placed at '0' for now
					TxD <= DataIN(10);	
				
				elsif(count_bits = 23) then
					TxD <= DataIN(11);			
				
				elsif(count_bits = 24) then
					if(sop_ind = '1') then
						TxD <= '1';
					else
						TxD <= '0';
					end if;
				
				elsif(count_bits = 25) then
					if(sop_ind = '1') then
						TxD <= '1';
						sop_ind := '0'; -- remise à 0 après utilisation
						
					else
						TxD <= '0';
					end if;
				
				elsif(count_bits = 26) then
					TxD <= '1'; 						-- stop bit first trame
				
				else
					TxD <= '1';							-- Ligne at rest when not sending data
					
					
				end if;
				
				-- remise à jours de la synchro
				startTr_lastVal := StartTr;
				
				-- clear counter if end if else add one to it
				if (count_bits > 29) then -- modifié (avant 28)
					count_bits := 0;
				elsif(count_bits = 0) then
					TxD <= '1';	
				else
					count_bits := count_bits + 1;
				end if;
				
	end if;			
	end if;
END PROCESS;
	
END USART_2f_beh;
