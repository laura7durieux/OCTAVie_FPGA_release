-- ============================================================================
-- Entity: bit_select
-- Architecture: bit_select_beh
-- Description:
--   Dynamic bit-window selector controlled by two push buttons.
--   This module allows the user to select a 12-bit window within a 24-bit input
--   vector (datain). Two push buttons increment or decrement the window’s
--   starting bit index. The selected 12-bit segment is sent to dataout.
--
-- Context of use:
--   Part of the OCTAVie FPGA processing chain, this block allows manual
--   inspection or dynamic selection of a subset of FFT or ADC data for display
--   or debugging purposes.
--
-- Operation summary:
--   - BPplus increments the bit window position (index + 1).
--   - BPmoins decrements the bit window position (index - 1).
--   - Buttons are active low, hence the inversion with “not”.
--   - The output dataout corresponds to datain(index+11 downto index).
--   - Boundaries are clamped between 0 and 12 to ensure valid slicing.
--
-- Notes:
--   - Rising-edge triggered on clk.
--   - Internal variables store the previous button states for edge detection.
--   - No reset is used: index initializes to 0 on FPGA power-up.
--   - Designed for low-frequency button inputs; not debounced.
--
-- Revision history:
--   v1.0 – Initial implementation and documentation for HardwareX article.
-- 
-- Author : L. Durieux
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- ============================================================================
-- Entity declaration
-- ============================================================================
entity bit_select is
	port(
		datain  : in  std_logic_vector(23 downto 0);  -- 24-bit input data
		BPmoins : in  std_logic;                      -- Decrement button (active low)
		BPplus  : in  std_logic;                      -- Increment button (active low)
		clk     : in  std_logic;                      -- System clock
		dataout : out std_logic_vector(11 downto 0)   -- Selected 12-bit output window
	);
end bit_select;

-- ============================================================================
-- Architecture implementation
-- ============================================================================
architecture bit_select_beh of bit_select is
begin

	-- Main process: triggered on rising edge of clk
	PROCESS(clk)
		-- Track button states for edge detection
		variable BPmoins_current : std_logic := '0';
		variable BPmoins_last    : std_logic := '0';
		variable BPplus_current  : std_logic := '0';
		variable BPplus_last     : std_logic := '0';
		
		-- Index defines the starting bit of the selected 12-bit window
		variable index : integer range 0 to 12 := 0;
	BEGIN

		-- Rising-edge detection on clock
		IF ((clk'event) and (clk = '1')) THEN

			-- Update button states (buttons are active low → inverted)
			BPmoins_last   := BPmoins_current;
			BPmoins_current := not(BPmoins);
			BPplus_last    := BPplus_current;
			BPplus_current := not(BPplus);

			-- Detect rising edges of buttons and update index accordingly
			if ((BPmoins_last = '0') and (BPmoins_current = '1')) then
				if (index = 0) then
					index := 0;              -- Lower bound limit
				else
					index := index - 1;      -- Decrement window start
				end if;

			elsif ((BPplus_last = '0') and (BPplus_current = '1')) then
				if (index = 12) then
					index := 12;             -- Upper bound limit
				else
					index := index + 1;      -- Increment window start
				end if;
			end if;

			-- Update output: extract a 12-bit slice of datain
			dataout <= datain((index + 11) downto index);

		END IF;
	END PROCESS;

end architecture;
