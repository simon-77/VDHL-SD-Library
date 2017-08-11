--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- A VHDL-Library for reading SD-Cards with a FPGA inside a small test project.
-- Copyright (C) 2017  Simon Aster
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
--############################################
--############################################
-- Library:		sd
-- File:			sd_transceiver.vhd
-- Author:		Simon Aster
-- Created:		2017-03-09
-- Modified:	2017-05-19
-- Version:		7.1
--############################################
--############################################
-- Short Description:
--------------------
-- This sd-controler talks to an SD-Card.
--============================
--============================
-- Overview:
--------------------
-- When 'cmd_start' is high for one 'sd_clk_en_o' periode,
-- the transmission of the command 'cmd' to the SD-Card will start.
-- This unit will wait for the expected response ('cmd.response')
-- and checks it (common bits and crc checksum). The received response
-- is written on the corresponding output 'resp' or 'csd'.
--------------------
-- Parallel data can be received. A tick of 'dat_start_read' will
-- start the listening for new data. The incomming data is written
-- to 'dat_block_read' and a tick on 'dat_tick_read' will indicate that
-- the transmission has finished.
--============================
--============================
-- !!!!! IMPORTANT NOTE !!!!!
-- ALL ticks, periodes, clock-cycles and so on correspond to
-- 'sd_clk_en_o'.
--============================
--============================
-- Signal Description:
--------------------
-- 'rst' (low active) system wide reset
-- 'clk' (positive edge) system wide clock
------------------
-- 'sd_clk_en_o' is an clock-enable output.
--====================
-- 'sd_clk' clock of sd-card
-- 'sd_cmd' command line of sd-card
-- 'sd_dat' data lines of sd-card
--====================
-- 'sleep' sets device into sleep mode ('sd_clk_en_o' is disabled)
--		'0' : run
--		'1' : sleep
-- 'fast' selects the clock frequency used for this whole unit,
--		'0'	: 400kHz
--		'1'	: 50MHz
-- 'wide_bus' selects 1-bit or 4-bit sd mode for data transmission
--		'0' : 1-bit sd mode
--		'1' : 4-bit sd mode
-- !!!!! IMPORTANT NOTE !!!!!
-- The command to set the sd-card into 4-bit mode must be set by the unit above.
-- This value just decides how the sd_dat lines are interpreted.
--%%%%%%%%%%%%%%%%
-- 'cmd' is the command that is written next
-- 'cmd_start' tick starting the transmittion of the command
-- 'cmd_fb' a tick signaling that the transmission
--					of the command 'cmd' has started.
------------------
-- 'resp' holds the response data for for some response types.
-- 'csd' holds the response data for some response types.
-- 'resp_stat' gives the error status of the received response.
-- 'resp_tick' a tick signaling that the other response related
--							signals are valid and that the transmission of
--							a new command can be started.
--%%%%%%%%%%%%%%%%
-- 'dat_start_read' tick starting the reception of data
-- 'dat_fb_read' a tick indication that this unit is waiting for data
-- 'dat_stop_read'	if this signal is high, the reading procedure is
--									aborted.
------------------
-- 'dat_block_read' payload data that was read
-- 'dat_stat_read' gives the error status of the received data
-- 'dat_tick_read' a tick indicating that a new block is available
--%%%%%%%%%%%%%%%%
-- 'status_start_read'	starts read of "Wide Width Data"; 512 bits status; e.g. acmd13, acmd51, ...
-- 'status_width'				Number of bits of the receiving status
-- 'status_fb_read'			a tick indication that this unit is waiting for status
------------------
-- 'status_tick_read'		a tick indicating that a new block of 512 bits is read
--============================
--============================
-- Clock
-- The sd-card is also reacting on the positive edge.
-- The clock signal for the sd-card is inverted. Thus
-- the sd-card triggers when the local clock has a falling edge.
-- Timing issues are oppressed with this methode.
--============================
--============================
-- Response
--------------------
-- The output that shows the response depends on 'cmd.resp'.
-- All other outputs are 'dont care'.
--------------------
-- valid output according to 'cmd.resp':
--		R0:											no output.
--		R1, R1b, R3, R6, R7:		'resp'
--		R2:											'cmd'
--------------------
-- 'resp.resp' is always 'cmd.response'.
--------------------
-- While this unit is receiving the response from the SD-Card,
-- the response is checked for errors. 'resp_stat' represents
-- the error status. Refere to 'sd_const_pkg.vhd' for further
-- details about error status.
----------
-- The output 'resp_stat' is not latched.
-- After the transmission of the command 'resp_stat'
-- will be reset to 'resp_stat_valid'. When an error occours, the
-- corresponding bit will be set to '1';
----------
-- The response R1b has an optionally busy signal. After this
-- response is received, sd_dat(0) is checked for a busy signal ('0').
-- After 1 s a timout will occure.
--============================
--============================
-- Data
-- when the start tick for data 'dat_start_read' is detected,
-- and the card is not busy (sd_dat(0) /= '0'), then this unit
-- will go to a wait-state. When the start-bit is received,
-- the data is shifted in. After transmittion the crc is checked.
-- The received data is available in 'dat_block_read'. 'dat_stat_read'
-- indicates the status of the received data and a tick on
-- 'dat_tick_read' indicates that the transmission has finished.
----------
-- When this unit is put into wait-state, there is a timout of
-- 1 s. When there is no stopbit after 1 s, an error will occure
-- and the unit goes with a tick on 'dat_tick_read' back to idle.
----------
-- 'dat_stat_read' is, like 'resp_stat', not latched.
-- 'dat_block_read' is not latched as well. It get's set to 0
-- on reset und new incomming data will overwrite this signal
-- consequently. 'dat_block_read' is only valid from tick
-- 'dat_tick_read' to incomming tick 'dat_start_read'.
----------
-- When the read sequence get's interrupted by a high signal of
-- 'dat_stop_read', no 'dat_tick_read' will be sent.
-- 'dat_stat_read' shows the current status (incomplete)
-- 'dat_block_read' shows the previously received data overwritten
-- with data that was read until the stop signal occured.
--============================
--============================
-- Status
-- Some commands (acmd13(SD Status), acmd51(SCR), ...) return some status bits
-- on dat-lines. To read this "Wide With Data", issue a tick on
-- 'status_start_read'. 'status_width' is the number of bits read.
-- This number should be dividable by 4 in 4-bit mode and greater than 0.
----------
-- A tick on 'status_tick_read' indicates a finished transmission.
-- The transmission times out after 1 s. This leads to an error but the
-- tick is sent always.
----------
-- For status and data the outputs of dat-read are used.
-- 'dat_stat_read' shows the status of this wide-width-data read operation.
-- All 1st bits (index=0) of 'dat_block_read' are used for status bits.
-- e.g.:	status bit 7   = dat_block_read(7)(0)
--				status bit 511 = dat_block_read(511)(0)
-- All other bits are don't care
--============================
--============================
--############################################
--############################################


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;
--------------------
use work.vhdl_lib_pkg.prescaler;
use work.vhdl_lib_pkg.ff_rs;
--------------------
use work.sd_const_pkg.all;
use work.sd_pkg.crc;
--------------------


entity sd_transceiver is
port(
	--====================
	-- System
	rst					: in  std_ulogic;
	clk					: in  std_ulogic;
	------------------
	sd_clk_en_o	: out std_ulogic;
	--====================
	-- drag through to SD-Card
	sd_clk			: out		std_ulogic;
	sd_cmd			: inout	std_logic;
	sd_dat			: inout	std_logic_vector(3 downto 0);
	--====================
	-- I/O to unit above
	------------------
	sleep						: in  std_ulogic := '0';
	fast						: in	std_ulogic := '0';
	wide_bus				: in  std_ulogic := '0';
	--%%%%%%%%%%%%%%%%
	cmd							: in	cmd_record;
	cmd_start				: in  std_ulogic;
	cmd_fb					: out std_ulogic;
	------------------
	resp						: out cmd_record;
	csd							: out csd_type;
	resp_stat				: out resp_stat_type;
	resp_tick				: out std_ulogic;
	--%%%%%%%%%%%%%%%%
	dat_start_read	: in  std_ulogic := '0';
	dat_fb_read			: out std_ulogic;
	dat_stop_read		: in  std_ulogic := '0';
	------------------
	dat_block_read	: out dat_block_type;
	dat_stat_read		: out dat_stat_type;
	dat_tick_read		: out std_ulogic;
	--%%%%%%%%%%%%%%%%
	status_start_read	: in  std_ulogic := '0';
	status_width			: in  natural range 1 to 512 := 512;
	status_fb_read		: out std_ulogic;
	------------------
	status_tick_read	: out std_ulogic
	--====================
);
end sd_transceiver;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture sd_transceiver_a of sd_transceiver is
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- fsm for cmd
	type state_type is (s_init, s_idle, s_cmd_init, s_cmd_wr, s_cmd_crc, s_cmd_stop, s_resp_init, s_resp_su, s_resp_rd, s_resp_crc, s_resp_stop, s_resp_busy, s_resp_fin);
	signal state		: state_type;
	--==========================
	-- fsm for dat
	type dat_state_type is (s_idle, s_wait, s_read, s_crc);
	signal dat_state, dat_state_dly	: dat_state_type;
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- 1s counter constant
	constant	timeout_1s_slow	: natural := 400e3;	-- 400 kHz
	constant	timeout_1s_fast	: natural :=  50e6;	--  50 MHz
	signal		timeout_1s			: natural range 0 to 50e6;
	--==========================
	-- counter and maximum constants for cmd
	constant init_max			: natural := 74;
	constant resp_timeout	: natural := 100; -- recommended: 64 cycles
	-- cmd_shift'length = 40
	-- resp cnt for R2 = 120
	signal cnt	: natural range 0 to 50e6; -- !!!!! must be larger than the maximum number above !!!!!
	--==========================
	-- counter and maximum constants for dat
	constant block_cnt_4bit	: natural := blocklen*2;
	constant block_cnt_1bit	: natural := blocklen*8;
	-- blocklen = 512
	signal dat_cnt : natural range 0 to 50e6; -- !!!! must be larger than maximum number above !!!!
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- registers for cmd
	signal cmd_reg		: cmd_record;
	-- shift registers for shifting data in and out
	signal cmd_shift	: std_ulogic_vector(39 downto 0); -- no crc, no end bit
	signal resp_shift	: std_ulogic_vector(135 downto 0);
	--==========================
	-- registers for dat
	type dat_packet_type_type is (usual, wide_width);
	signal dat_packet_type	: dat_packet_type_type;
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- signals for crc7 unit
	signal crc_rst, crc_en, crc_shift, crc_out			: std_ulogic;
	--==========================
	-- signals for crc16 unit (dat)
	signal crc_dat_rst, crc_dat_en, crc_dat_shift		: std_ulogic;
	signal crc_dat_out															: std_ulogic_vector(sd_dat'length-1 downto 0);
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- signals for creating 'clk_en_init' and 'clk_init' with 400kHz
	signal clk_en_init2		: std_ulogic;
	signal clk_en_init		: std_ulogic;
	signal clk_init				: std_ulogic;
	-- temporary signals
	signal sd_clk_temp		: std_ulogic;
	signal sd_clk_en_temp	: std_ulogic;
	signal enable_clk			: std_ulogic;
	--====================
	-- global clock-enable signal
	signal sd_clk_en			: std_ulogic;
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	sd_clk_en_o <= sd_clk_en;

	--####################################
	-- calculate crc7 for cmd
	u_cmd_crc7:		crc generic map (length=>crc7_len, polynomial=>crc7_pol) port map (rst=>rst, clk=>clk, clk_en=>sd_clk_en,
								rst_crc=>crc_rst, en_crc=>crc_en, shift_out=>crc_shift, dat_in=>sd_cmd, dat_out=>crc_out);
	--====================
	-- calculate crc16 for dat
	crc16: for i in 0 to sd_dat'length-1 generate begin
		crc16_dat_i:	crc generic map (length=>crc16_len, polynomial=>crc16_pol) port map (rst=>rst, clk=>clk, clk_en=>sd_clk_en,
									rst_crc=>crc_dat_rst, en_crc=>crc_dat_en, shift_out=>crc_dat_shift, dat_in=>sd_dat(i), dat_out=>crc_dat_out(i));
	end generate;
	--####################################


	--####################################
	-- Create 400kHz clk "clk_init" and clock-enable "clk_en_init"
	u_clk_en_init2:		prescaler generic map (divisor=>CLK_FREQ/800e3) port map (rst=>rst, clk=>clk, o_clk_en=>clk_en_init2);
	u_clk_en_init:		prescaler generic map (divisor=>2) port map (rst=>rst, clk=>clk, i_clk_en=> clk_en_init2, o_clk_en=>clk_init);
	clk_en_init <= clk_en_init2 and clk_init;
	--####################################


	--####################################
	-- select slow (400kHz) and fast (50MHz) clock and clock-enable
	with fast select
		sd_clk_en_temp <= '1' when '1',
											clk_en_init when others;
	------------------
	with fast select
		sd_clk_temp <= not clk when '1',			-- invert clock => sd-card triggers when 'clk' has a falling edge
									 clk_init when others;	-- clk_init has a falling edge, when 'clk_en_init' is a tick
	------------------
	sd_clk_en <= sd_clk_en_temp and enable_clk;
	sd_clk		<= sd_clk_temp		and enable_clk;
	--====================
	-- delay input 'sleep' to next clk-periode
	sleep_sync: process(rst, clk)
	begin
		if rst = '0' then
			enable_clk <= '0';
		elsif clk'event and clk = '1' then
			if sd_clk_en_temp = '1' then
				enable_clk <= not sleep;
			end if;
		end if;
	end process;
	--====================
	-- set value for 1s-timout according to clock frequency
	with fast select
		timeout_1s <= timeout_1s_fast when '1',
									timeout_1s_slow when others;
	--####################################


	--####################################
	-- fsm cmd
	-- set outputs according to state
	with state select
		sd_cmd <=			cmd_shift(cmd_shift'length-1) when s_cmd_wr,
									crc_out when s_cmd_crc,
									'1' when s_cmd_stop,
									'1' when s_init,
									'Z' when others;
	------------------
	with state select
		crc_rst <=		'1' when s_cmd_init,
									'1' when s_resp_init,
									'0' when others;
	------------------
	with state select
		crc_en <=			'1' when s_cmd_wr,
									'1' when s_resp_rd,
									'0' when others;
	------------------
	with state select
		crc_shift <=	'1' when s_cmd_crc,
									'1' when s_resp_crc,
									'0' when others;
	------------------
	with state select
		cmd_fb <=			'1' when s_cmd_init,
									'0' when others;
	------------------
	with state select
		resp_tick <=	'1' when s_resp_fin,
									'0' when others;
	--====================
	-- fsm dat
	-- set outputs according to state
	sd_dat <= (others=>'Z');
	------------------
	with dat_state select
		crc_dat_rst <=		'1' when s_wait,
											'0' when others;
	------------------
	with dat_state select
		crc_dat_en <=			'1' when s_read,
											'0' when others;
	------------------
	with dat_state select
		crc_dat_shift <=	'1' when s_crc,
											'0' when others;
	------------------
	dat_fb_read <=			'1' when (dat_state = s_wait) and (dat_state /= dat_state_dly) and (dat_packet_type = usual) else
											'0';
	------------------
	dat_tick_read <=		'1' when (dat_state = s_idle) and (dat_state /= dat_state_dly) and (dat_packet_type = usual) else
											'0';
	------------------
	status_fb_read <=			'1' when (dat_state = s_wait) and (dat_state /= dat_state_dly) and (dat_packet_type = wide_width) else
												'0';
	------------------
	status_tick_read <=		'1' when (dat_state = s_idle) and (dat_state /= dat_state_dly) and (dat_packet_type = wide_width) else
												'0';
	--####################################



	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	p_sd_transceiver: process(rst, clk)
		variable resp_var	: cmd_record;
		----------------
	begin
	--####################################
	if rst = '0' then
		--==========================
		-- signal for cmd
		state <= s_init;
		cnt		<= 0;

		resp <= ((others=>'0'), (others=>'0'), R0);
		csd	 <= (others=>'0');
		resp_stat <= resp_stat_valid;

		cmd_reg		 <= ((others=>'0'), (others=>'0'), R0);
		cmd_shift	 <= (others=>'0');
		resp_shift <= (others=>'0');
		--==========================
		-- signals for dat
		dat_state			<= s_idle;
		dat_state_dly <= s_idle;
		dat_cnt				<= 0;

		dat_block_read <= (others=>(others=>'0'));
		dat_stat_read	 <= dat_stat_valid;

		dat_packet_type <= usual;

	--####################################
	elsif clk'event and clk = '1' then
		if sd_clk_en = '1' then
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for dat

			-- Always count counter one up.
			-- Reset it when neccesairy laiter.
			cnt <= cnt + 1;

			case state is
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- init / idle
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- initialize card with 74 clock cycles while
				-- 'sd_cmd' is '1' to enter SD-Mode
				when s_init =>
					if cnt = 74 then
						state <= s_idle;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- wait for 'cmd_start' to write a new command
				when s_idle =>
					if cmd_start = '1' then
						state <= s_cmd_init;
						cmd_reg <= cmd;
					end if;
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- write
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- prepare for write
				when s_cmd_init =>
					state <= s_cmd_wr;
					cnt <= 0;
					-- '0': start bit; '1': transmitt bit (1 = host to card)
					cmd_shift <= "01" & cmd_reg.index & cmd_reg.arg;
				--§§§§§§§§§§§§§§§§§§§§
				-- shift command out to card
				when s_cmd_wr =>
					cmd_shift <= cmd_shift(cmd_shift'length-2 downto 0) & '0';
					if cnt = (cmd_shift'length-1) then
						state <= s_cmd_crc;
						cnt <= 0;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- write crc7 checksum to card
				when s_cmd_crc =>
					if cnt = (crc7_len-1) then
						state <= s_cmd_stop;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- transmit stop bit
				when s_cmd_stop =>
					state <= s_resp_init;
					cnt <= 0;
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- read
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- prepare for read
				when s_resp_init =>
					-- clear previous errors
					resp_stat <= resp_stat_valid;
					-- R0 has no response
					if cmd_reg.resp = R0 then
						state <= s_resp_fin;
					-- wait for start bit of response
					elsif sd_cmd = '0' then
						state <= s_resp_su;
						cnt <= 0;
						resp_shift <= (others=>'0');
					-- check for timeout
					elsif cnt = resp_timeout then
						state <= s_resp_fin;
						resp_stat(e_timeout) <= '1';
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- prepare for read
				when s_resp_su =>
					-- note: transmission bit is sent now (always '0' => not needed for crc)
					if (sd_cmd /= '0') and (cnt = 0) then
						resp_stat(e_common) <= '1';
					end if;

					resp_shift <= resp_shift(resp_shift'length-2 downto 0) & sd_cmd;
					case cmd_reg.resp is
						when R1 | R1b | R3 | R6 | R7 =>
							state <= s_resp_rd;
							cnt <= 0;
						when R2 =>
							-- first 6 bits are reserved '111111' and not calculated for crc
							-- 1 transmission bit + 6 reserved bits = 7 bits - 1 = 6
							if cnt = 6 then
								state <= s_resp_rd;
								cnt <= 0;
							end if;
						when others =>
							state <= s_resp_fin;
							resp_stat(e_unknown) <= '1';
					end case;
				--§§§§§§§§§§§§§§§§§§§§
				-- shift in data
				when s_resp_rd =>
					resp_shift <= resp_shift(resp_shift'length-2 downto 0) & sd_cmd;

					case cmd_reg.resp is
						when R1 | R1b | R6 | R7 =>
							-- 6 index + 32 status
							if cnt = 37 then
								state <= s_resp_crc;
								cnt <= 0;
							end if;
						when R2 =>
							-- 127 CSD - 7 crc
							if cnt = 119 then
								state <= s_resp_crc;
								cnt <= 0;
							end if;
						when R3 =>
							-- 6 reserved + 32 status + 7 reserved
							if cnt = 44 then
								state <= s_resp_stop;
								cnt <= 0;
							end if;
						when others =>
							state <= s_resp_fin;
							resp_stat(e_unknown) <= '1';
					end case;
				--§§§§§§§§§§§§§§§§§§§§
				-- check crc
				when s_resp_crc =>
					resp_shift <= resp_shift(resp_shift'length-2 downto 0) & sd_cmd;

					if sd_cmd /= crc_out then
						resp_stat(e_crc) <= '1';
					end if;

					if cnt = (crc7_len-1) then
						state <= s_resp_stop;
						cnt <= 0;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- check received response and write it to output according to 'cmd.resp'
				when s_resp_stop =>
					-- stop bit: should be '1'
					if sd_cmd /= '1' then
						resp_stat(e_common) <= '1';
					end if;
					state <= s_resp_fin;
					cnt <= 0;
					-- response R1b: check busy signal
					if cmd_reg.resp = R1b then
						state <= s_resp_busy;
					end if;

					-- temp storage of response
					resp_var.index := resp_shift(44 downto 39);
					resp_var.arg := resp_shift(38 downto 7);

					--=============
					case cmd_reg.resp is
						when R1 | R1b | R6 =>
							resp <= resp_var;
							if resp_var.index /= cmd_reg.index then
								resp_stat(e_common) <= '1';
							end if;
							----------
						when R2 =>
							csd <= resp_shift(126 downto 0) & '1'; -- bit(0): not used; always '1'
							if resp_shift(132 downto 127) /= "111111" then
								resp_stat(e_common) <= '1';
							end if;
							----------
						when R3 =>
							resp <= resp_var;
							if (resp_var.index /= "111111") or (resp_shift(6 downto 0) /= "1111111") then
								resp_stat(e_common) <= '1';
							end if;
							----------
						when R7 =>
							resp <= resp_var;
							if (resp_var.index /= cmd_reg.index) or (resp_var.arg(31 downto 12) /= x"00000") or (resp_var.arg(7 downto 0) /= cmd_reg.arg(7 downto 0)) then
								resp_stat(e_common) <= '1';
							end if;
							----------
						when others =>
							resp_stat(e_unknown) <= '1';
					end case;
					--=============

					resp.resp <= cmd_reg.resp;
				--§§§§§§§§§§§§§§§§§§§§
				-- response type R1b: wait when busy
				when s_resp_busy =>
					-- sd_dat(0) = '0' => busy
					if sd_dat(0) = '1' then
						state <= s_resp_fin;
					end if;

					-- timout after 1 s
					if cnt = (timeout_1s-1) then
						resp_stat(e_common) <= '1';
						state <= s_resp_fin;
					end if;

				--§§§§§§§§§§§§§§§§§§§§
				-- finish transaction and go to idle
				when s_resp_fin =>
					state <= s_idle;
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				when others =>
					state <= s_init;
			end case;

			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for dat

			-- delay dat_state for 1 clk-periode
			dat_state_dly <= dat_state;

			-- Always count counter one up.
			dat_cnt <= dat_cnt + 1;


			case dat_state is
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- idle
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- wait for start signal
				when s_idle =>
					-- if card is not busy
					if sd_dat(0) /= '0' then
						-- usual data
						if dat_start_read = '1' then
							dat_state <= s_wait;
							dat_cnt <= 0;
							dat_stat_read <= dat_stat_valid;
							dat_packet_type <= usual;
							-- wide-width data
						elsif status_start_read = '1' then
							dat_state <= s_wait;
							dat_cnt <= 0;
							dat_stat_read <= dat_stat_valid;
							dat_packet_type <= wide_width;
						end if;
					end if;
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- read
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- wait for start bit or timeout
				when s_wait =>
					if wide_bus = '1' then
						-- 4-bit sd mode
						if sd_dat = "0000" then
							dat_state <= s_read;
							dat_cnt <= 0;
						end if;
					--============
					else
						-- 1-bit sd mode
						if sd_dat(0) = '0' then
							dat_state <= s_read;
							dat_cnt <= 0;
						end if;
					end if;

					if dat_cnt = timeout_1s then
						dat_stat_read(e_timeout) <= '1';
						dat_state <= s_idle;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- read data from sd_dat
				when s_read =>
					if wide_bus = '1' then
						-- 4-bit sd mode
						case dat_packet_type is
							-- usual data
							when usual =>
								dat_block_read(dat_cnt/2)((1-(dat_cnt mod 2))*4+3 downto (1-(dat_cnt mod 2))*4) <= std_ulogic_vector(sd_dat);
								if dat_cnt = (block_cnt_4bit-1) then
									dat_state <= s_crc;
									dat_cnt <= 0;
								end if;
							-- wide-width data
							when wide_width =>
								dat_block_read((status_width-4*dat_cnt)-4)(0) <= std_ulogic(sd_dat(0));
								dat_block_read((status_width-4*dat_cnt)-3)(0) <= std_ulogic(sd_dat(1));
								dat_block_read((status_width-4*dat_cnt)-2)(0) <= std_ulogic(sd_dat(2));
								dat_block_read((status_width-4*dat_cnt)-1)(0) <= std_ulogic(sd_dat(3));
								if dat_cnt = (status_width/4-1) then
									dat_state <= s_crc;
									dat_cnt <= 0;
								end if;
						end case;
					--============
					else
						-- 1-bit sd mode
						case dat_packet_type is
							-- usual data
							when usual =>
								dat_block_read(dat_cnt/8)(7-(dat_cnt mod 8)) <= std_ulogic(sd_dat(0));
								if dat_cnt = (block_cnt_1bit-1) then
									dat_state <= s_crc;
									dat_cnt <= 0;
								end if;
							-- wide-width data
							when wide_width =>
								dat_block_read(status_width-dat_cnt-1)(0) <= std_ulogic(sd_dat(0));
								if dat_cnt = (status_width-1) then
									dat_state <= s_crc;
									dat_cnt <= 0;
								end if;
						end case;
					end if;

				--§§§§§§§§§§§§§§§§§§§§
				-- check crc of received data
				when s_crc =>
					if wide_bus = '1' then
						-- 4-bit sd mode
						if std_ulogic_vector(sd_dat) /= crc_dat_out then
							dat_stat_read(e_crc) <= '1';
						end if;
					--============
					else
						-- 1-bit sd mode
						if std_ulogic(sd_dat(0)) /= crc_dat_out(0) then
							dat_stat_read(e_crc) <= '1';
						end if;
					end if;

					if dat_cnt = (crc16_len-1) then
						dat_state <= s_idle;
					end if;
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				when others =>
					dat_state <= s_idle;
					dat_state_dly <= s_idle;
			end case;
			--8888888888888888888888888888888888888888888
			if dat_stop_read = '1' then
				dat_state <= s_idle;
				dat_state_dly <= s_idle;
			end if;

		end if;
	end if;
	--####################################
	end process;
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
end sd_transceiver_a;
