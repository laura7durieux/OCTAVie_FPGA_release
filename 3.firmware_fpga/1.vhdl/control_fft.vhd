-- ============================================================================
-- Entity: control_fft
-- Architecture: control_fft_bh
-- Description:
--   Control block for an FFT IP core using an Avalon-ST–like handshake.
--   Generates SOP/EOP/VALID and a short RESET pulse at startup, sets the
--   FFT length, and routes the input samples to the FFT real input while
--   zeroing the imaginary part.
--
-- Interface:
--   Inputs:
--     CLK         – System clock driving the controller.
--     in_signal   – 12-bit input sample stream (mapped to FFT real input).
--   Outputs:
--     sink_valid  – Asserted when input data is valid.
--     sink_sop    – Start-of-packet indicator (first sample of a frame).
--     sink_eop    – End-of-packet indicator (last sample of a frame).
--     inverse     – '0' to perform forward FFT.
--     source_ready– Asserted to indicate downstream is ready (here tied high
--                   during the initial valid window; used as a simple model).
--     sink_error  – 2-bit error bus (not used, forced to "00").
--     fft_pts     – Encoded FFT size selector (here set to 512 points).
--     outreal     – Real data stream fed to the FFT (passthrough of in_signal).
--     outimag     – Imaginary data stream fed to the FFT (zeroed).
--     reset       – Short pulse after power-up to (re)initialize the FFT IP.
--
-- Operation:
--   - A frame is 512 samples long. A down-counter 'count' runs from 512 to 0:
--       * When count = 1  → sink_eop = '1' (marks last sample)
--       * When count = 0  → reload to 512 and raise sink_sop = '1' (first sample)
--   - A secondary counter 'count_rst' generates a short RESET pulse and a brief
--     window where sink_valid and source_ready are asserted at startup.
--   - Imaginary input is hard-wired to zero; inverse is hard-wired to forward.
--
-- Notes:
--   - This skeleton assumes constant, contiguous frames of 512 samples.
--   - Handshake is simplified: sink_valid/source_ready are only pulsed shortly
--     after reset (can be adapted as needed by the system integrator).
--   - The exact encoding of fft_pts (here "1000000000") matches a 512-pt mode
--     expected by the FFT IP configuration used in the project.
--
-- Revision history:
--   v1.0 – English documentation added for HardwareX.
-- 
-- Author : L. Durieux
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity control_fft is
	--generic(Tw : integer := 5);

	port(
		CLK       : in  std_logic;                             -- Clock
		in_signal : in  std_logic_vector(11 downto 0);         -- Data

		sink_valid, sink_sop, sink_eop, inverse, source_ready : out std_logic; -- FFT control
		sink_error : out std_logic_vector (1 downto 0);        -- Error bus (unused)

		fft_pts : out std_logic_vector (9 downto 0);           -- FFT length selector

		outreal, outimag : out std_logic_vector(11 downto 0);  -- Real/Imag presented to FFT

		reset : out std_logic                                  -- Reset pulse for FFT IP
	);
end control_fft;

-- architecture
architecture control_fft_bh of control_fft is
begin

	-- Static control assignments
	inverse    <= '0';        -- Forward FFT (not inverse)
	sink_error <= "00";       -- No error reporting in this block

	-- Select FFT length (IP-specific coding): "1000000000" → 512 points
	fft_pts <= "1000000000";

	-- Route input to real part; imaginary part zeroed
	outreal <= in_signal;
	outimag <= (others => '0');

	-- Control logic
	process(CLK)

		variable count     : integer := 512; -- Counts remaining samples in a 512-sample frame
		variable count_rst : integer := 10;  -- Startup countdown to issue RESET and short VALID window

	begin
		-- Generate SOP/EOP and startup handshake on rising clock
		if ((CLK'event) and (CLK = '1')) then
			-- Advance frame counter
			count := count - 1;

			-- EOP one cycle before wrap
			if (count = 1) then
				sink_eop <= '1';
			else
				sink_eop <= '0';
			end if;

			-- SOP when wrapping the frame
			if (count = 0) then
				count    := 512;
				sink_sop <= '1';
			else
				sink_sop <= '0';
			end if;

			-- Startup control: issue a short reset pulse, then a brief VALID/READY
			if (count_rst > 0) then
				count_rst := count_rst - 1;
			end if;

			-- Assert reset for a few cycles after power-up
			if (count_rst < 4) then
				reset <= '1';  -- Active-high reset pulse for the FFT IP
			else
				reset <= '0';
			end if;

			-- Briefly assert sink_valid and source_ready after reset
			if (count_rst < 2) then
				sink_valid   <= '1';
				source_ready <= '1';
			else
				sink_valid   <= '0';
				source_ready <= '0';
			end if;

		end if;
	end process;

end architecture;
