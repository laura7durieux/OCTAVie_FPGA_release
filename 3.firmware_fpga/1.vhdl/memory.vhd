-- ============================================================================
-- Entity: memory
-- Architecture: memory_beh
-- Description:
--   Simple dual-phase sample buffer with synchronous, active-low clear.
--   On the rising edge of 'sop', the module starts a write/read sequence:
--     • Writes incoming 12-bit samples into a 256-word RAM (addresses 0..255)
--       on two consecutive clock fronts (count_clk = 1 or 2).
--     • Reads out one sample every second clock front (count_clk = 2),
--       outputting the current data_in for the very first read, then serving
--       buffered samples from RAM thereafter.
--   The 'sop_out' pulse marks the start of data emission, and 'sotrame' is a
--   strobe asserted on read cycles when data_out is valid.
--
-- Interface:
--   Inputs:
--     clk     – System clock.
--     sop     – Start-of-packet (asserting a new write/read cycle).
--     clr     – Active-low synchronous clear (flush RAM and reset pointers).
--     data_in – 12-bit input sample.
--   Outputs:
--     sop_out – One-clock pulse indicating the beginning of output data.
--     sotrame – Read strobe: high when data_out is updated (every other clk).
--     data_out– 12-bit output sample (first is passthrough, then from RAM).
--
-- Operation:
--   - Internal RAM 'mem' holds 256 samples of 12 bits.
--   - On clr = '0' (checked synchronously): RAM is cleared and pointers reset.
--   - A rising edge on 'sop' resets addresses, raises 'sop_out' for one cycle,
--     and arms the two-phase cadence controlled by count_clk:
--       * count_clk = 1 or 2 → write data_in to RAM, increment write_address.
--       * count_clk = 2       → output data (first passthrough, then mem[...] ),
--                               raise 'sotrame' for one clock.
--     After a read at count_clk = 2, count_clk toggles back to 1, creating the
--     "every other clock" read cadence.
--   - When read_address reaches 256, the sequence stops (count_clk := 0).
--
-- Notes:
--   - Clear is coded as active-low but is synchronous (process is clk-sensitive).
--   - 'sop_out' marks the start of *data emission* (not the frame boundary).
--   - RAM initialization on clear is explicit via a loop over all 256 entries.
--
-- Revision history:
--   v1.0 – English documentation added for HardwareX.
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity memory is
	port(
		clk, sop, clr : in  std_logic;
		sop_out, sotrame : out std_logic;                         -- indicates data emission start / read strobe
		data_in  : in  std_logic_vector(11 downto 0);
		data_out : out std_logic_vector(11 downto 0)
	);
end memory;

architecture memory_beh of memory is

    type MEMO is array (0 to 255) of std_logic_vector(11 downto 0);
    signal mem : MEMO;
    signal last_sop : std_logic :='0';

begin
readwrite : process(clk)
	variable count_clk : integer range 0 to 3 := 0;                 -- two-phase cadence: 1/2 for write, read on 2
	variable read_address, write_address : integer range 0 to 256 := 0;
begin
	-- Synchronous active-low clear: flush RAM and reset pointers/state
	if (clr = '0') then
		-- Clear all 256 memory locations
		for i in 0 to 255 loop
			mem(i) <= (others => '0');
		end loop;
		write_address := 0;
		read_address  := 0;

	elsif (clk'event and clk = '1') then
		-- Detect SOP rising edge to start a new write/read sequence
		if ((sop = '1') and (last_sop = '0')) then
			count_clk    := 1;
			write_address := 0;
			read_address  := 0;
			sop_out <= '1';                                        -- signal that data emission starts
		else 
			sop_out <= '0';
		end if;
		last_sop <= sop;

		-- Write path: store input samples during phases 1 and 2 (if space remains)
		if (((count_clk = 1) or (count_clk = 2)) and (write_address < 256)) then
			mem(write_address) <= data_in;
			write_address      := write_address + 1;
		end if;

		-- Read path: emit data every other clock (phase 2)
		if (count_clk = 2) then
			-- First word is passthrough (memory not yet populated at address 0)
			if (read_address = 0) then 
				data_out    <= data_in;
				read_address := read_address + 1;
			else
				data_out    <= mem(read_address);
				read_address := read_address + 1;
			end if;
			sotrame <= '1';                                        -- valid data_out strobe
		else
			sotrame <= '0';
		end if;

		-- Toggle cadence: after phase 2, go back to phase 1; after phase 1, advance to 2
		if (count_clk = 2) then 
			count_clk := 1;
		elsif (count_clk = 1) then
			count_clk := count_clk + 1;                            -- 1 → 2
		end if;
		
		-- Terminate sequence after 2*256 clocks (reads done)
		if (read_address = 256) then
			count_clk := 0;
		end if;

	end if;
end process;
end architecture;
