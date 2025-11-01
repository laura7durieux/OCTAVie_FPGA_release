-- ============================================================================
-- Entity: control_clk
-- Architecture: control_clk_beh
-- Description:
--   Simple clock divider.
--   This module generates a lower-frequency clock signal (clk_divided)
--   from a higher-frequency system clock (CLK). The output toggles each
--   time the internal counter reaches the specified "divider" value.
--
-- Interface:
--   Generic:
--     divider – integer division factor; determines the output frequency.
--   Inputs:
--     CLK – System clock input (e.g., 50 MHz).
--     rst – Active-low synchronous reset.
--   Outputs:
--     clk_divided – Divided clock output signal.
--
-- Operation:
--   - On every rising edge of CLK, the internal counter increments.
--   - When the counter reaches the divider value, the output clock toggles,
--     and the counter resets to zero.
--   - The resulting frequency is approximately:
--         f_out = f_in / (2 * divider)
--     since one full period corresponds to two toggles.
--   - Reset (rst = '0') clears the counter and drives the output low.
--
-- Notes:
--   - The reset is synchronous and active low.
--   - The divider value must be chosen to remain within integer range limits.
--   - Commonly used to generate slower SPI, ADC, or display clocks from
--     a single high-frequency source.
--
-- Revision history:
--   v1.0 – Documentation in English for HardwareX publication.
-- 
-- Author : L. Durieux
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity control_clk is
	generic(divider : integer := 125);
	port(
		CLK, rst : in std_logic;        -- 50 MHz system clock and active-low reset
		clk_divided : out std_logic     -- Output divided clock
	);
end control_clk;

architecture control_clk_beh of control_clk is

	signal internal_clk : std_logic := '0';  -- Internal divided clock signal

begin

	PROCESS (CLK, rst)
		variable counter : integer range 0 to divider := 0; -- Divider counter
	begin
		IF ((CLK'event) and (CLK = '1')) THEN
			-- Synchronous active-low reset
			IF (rst = '0') THEN 
				counter := 0;
				internal_clk <= '0';
			ELSE
				-- Clock division logic
				IF (counter = divider) THEN
					internal_clk <= not internal_clk; -- Toggle output
					counter := 0;
				ELSE 
					counter := counter + 1;           -- Increment counter
				END IF;
			END IF;
		END IF;
	END PROCESS;

	-- Assign internal clock to output
	clk_divided <= internal_clk;

end architecture;
