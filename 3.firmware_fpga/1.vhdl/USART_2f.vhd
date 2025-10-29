-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---------- USART	-----------------------------------------------------------------
--
-- Entity: USART_2f
-- Architecture: USART_2f_beh
-- Description:
--   Custom 2-frame UART-like serializer for a 12-bit word.
--   On a rising edge of StartTr, the module emits TWO serial frames on TxD.
--   Each frame uses an asynchronous-UART style:
--     • 1 start bit (0)
--     • 8 data bits (LSB first in this implementation)
--     • 1 stop bit (1)
--   Data mapping across the two frames:
--     • Frame #1 (counts 1..10): DataIN(0..5), then two flag bits mirroring 'sop'
--     • Frame #2 (counts 17..26): DataIN(6..11), then two flag bits mirroring 'sop'
--   The line idles high (TxD='1'). An active-low reset (RaS='0') clears the state.
--
-- Interface:
--   Inputs:
--     RaS      – Active-low synchronous reset (clears bit counter, sets TxD idle).
--     clk      – Bit clock (one serial bit is emitted per rising clk edge).
--     StartTr  – Start transmission strobe; rising edge kicks off the 2-frame burst.
--     sop      – Packet-start indicator; captured and duplicated into two flag bits
--                inside each frame (positions 7 and 8 in this design).
--     DataIN   – 12-bit parallel data to serialize across two frames.
--   Output:
--     TxD      – Serial output line (idle=‘1’, start=‘0’, stop=‘1’).
--
-- Notes:
--   - Bit order is LSB-first as implemented (DataIN(0) goes out before DataIN(11)).
--   - The two additional bits per frame are simple SOP flags (not parity).
--   - Baud rate equals the clk frequency; gating or further division is external.
--   - count_bits ranges over 0..29 to cover idle gaps and both frames.
--
-- Revision history:
--   v1.0 – English documentation added for publication.
-----------------------------------------------------------------------------------------

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

-- Build the UART-like serial frame sequence (two frames per StartTr)
PROCESS(clk)
VARIABLE count_bits : integer range 0 to 29 := 0;  -- total scheduling window (up to 30 steps)
VARIABLE startTr_lastVal : std_logic := '0';  
VARIABLE sop_lastVal : std_logic := '0'; 
VARIABLE sop_ind : std_logic := '0'; 

BEGIN
	if(clk'event and clk='1') then
	
		-- Active-low reset: return to idle line and clear counter
		if(RaS = '0') then 
			count_bits := 0;
			TxD <= '1'; -- line idle (mark state)
		
		else 
			-- Capture SOP rising edge → propagate as in-frame flags
			if(sop = '1' and sop_lastVal = '0') then
				sop_ind := '1';
			end if;
			
			-- Rising edge of StartTr → arm the bit scheduler (start at step 1)
			-- (Synchronizes with the producer so TxD sees stable data.)
			if(StartTr = '1' and startTr_lastVal = '0') then
				count_bits := 1;
			end if;
				
			-- Frame #1 bit scheduling
			if(count_bits = 1) then
				TxD <= '0';							-- start bit (frame #1)
				
			elsif(count_bits = 2) then 		-- LSB first
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
				-- SOP flag bit #1 in frame #1
				if(sop_ind = '1') then
					TxD <= '1';
				else
					TxD <= '0';
				end if;				
			
			elsif(count_bits = 9) then
				-- SOP flag bit #2 in frame #1
				if(sop_ind = '1') then
					TxD <= '1';
				else
					TxD <= '0';
				end if;				
			
			elsif(count_bits = 10) then
				TxD <= '1'; 						-- stop bit (frame #1)

			-- Frame #2 bit scheduling
			elsif(count_bits = 17) then
				TxD <= '0';							-- start bit (frame #2)
				
			elsif(count_bits = 18) then
				TxD <= DataIN(6);			-- LSB of upper half
				
			elsif(count_bits = 19) then
				TxD <= DataIN(7);
				
			elsif(count_bits = 20) then
				TxD <= DataIN(8);
				
			elsif(count_bits = 21) then
				TxD <= DataIN(9);
			
			elsif(count_bits = 22) then
				TxD <= DataIN(10);	
			
			elsif(count_bits = 23) then
				TxD <= DataIN(11);			
			
			elsif(count_bits = 24) then
				-- SOP flag bit #1 in frame #2
				if(sop_ind = '1') then
					TxD <= '1';
				else
					TxD <= '0';
				end if;
			
			elsif(count_bits = 25) then
				-- SOP flag bit #2 in frame #2 (then clear the indicator)
				if(sop_ind = '1') then
					TxD <= '1';
					sop_ind := '0'; -- clear after use
					
				else
					TxD <= '0';
				end if;
			
			elsif(count_bits = 26) then
				TxD <= '1'; 						-- stop bit (frame #2)
			
			else
				TxD <= '1';							-- idle line when not sending
			end if;
			
			-- Edge trackers for synchronization
			startTr_lastVal := StartTr;
			sop_lastVal     := sop;
			
			-- Counter management: wrap after the scheduling window; keep idle on 0
			if (count_bits > 29) then
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
