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
-- File:			simple_sd.vhd
-- Author:		Simon Aster
-- Created:		2017-06-01
-- Modified:	2017-06-03
-- Version:		1.5
--############################################
--############################################
-- Short Description:
--------------------
-- This unit provides a simple front-end for accessing an sd-card with this sd-library.
--============================
--============================
-- Overview:
--============================
-- 'rst' and 'clk' must be provided by the system.
-- 'sd_clk', 'sd_cmd' and 'sd_dat' should be directly connected to the sd-card.
-- 'sd_cd' is the card detect signal of the sd-socket. ('0' = card inserted). This signal *optional*.
--============================
-- 'sleep'				: a '1' will set this unit in sleep mode *optional*
-- 'mode'					: the mode of the sd-card can be selected (1-bit, 4-bit; slow, fast) *optional*
-- 'mode_fb'			: feedback of the current mode
--------------------
-- 'dat_address'	: (32 bit std_ulogic_vector) block address for the next read operation
--------------------
-- 'ctrl_tick'		: ticks controlling this unit (reinit, read_single, read_multiple, stop_transfer)
-- 'fb_tick'			: ticks indicating that the current action has started
--------------------
-- 'dat_block'		: data that was read from the sd-card
-- 'dat_valid'		: '1' if the read was successfull
-- 'dat_tick'			: a tick indicating that a new data block was read.
--------------------
-- 'unit_stat'		: feedback of the current unit status.
--============================
-- Sleep
--------------------
-- If 'sleep' is '1' the internal clock and the clock signal to the sd-card will be disabled. The whole unit is
-- stopped and neither outputs will change (ticks may be longer than one clock-cycle) nor inputs will be respected.
-- The data transfer to the sd-card can be interrupted by setting 'sleep' to '1' and resumed by setting the same
-- signal to '0' again.
--============================
-- Control
--------------------
-- This unit can be controlled by the signals of the record 'ctrl_tick'.
-- A tick will start the according action. A tick on the same signal of the record 'fb_tick' is the feedback that
-- this action has successfully started.
--
-- 'ctrl_tick.reinit'					: reinitialize the sd-card.
-- 'ctrl_tick.read_single'		: read a single data block
-- 'ctrl_tick.read_multiple'	: read multiple data blocks
-- 'ctrl_tick.stop_transfer'	: stop the read multiple blocks transfer
--============================
-- Data
--------------------
-- The data transfered with the sd-card is based on 512-byte large blocks.
-- One data block is available in the array 'dat_block'. The signal 'dat_valid' is '1' if the transmission
-- was successfull (no crc error, no timeout). A tick of the signal 'dat_tick' indicates that a new data block
-- was read. The signals 'dat_block' and 'dat_valid' are only valid for one clock-cylce while 'dat_tick' is '1'.
--============================
-- Unit Status
--------------------
-- The signal 'unit_stat' gives feedback of the current unit status.
-- 's_init'			: card is initializing => wait until initialisation has finished
-- 's_ready'		: card is initialized and ready for starting a data transmission
-- 's_read'			: This unit is reading data from the sd-card => read_single: wait until finished; read_multiple: stop transfer
-- 's_error'		: An error occured => reinitialize card
-- 's_no_card'	: No sd-card is inserted
--============================
--############################################
--############################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;
--------------------
use work.sd_const_pkg.all;
use work.sd_pkg.sd_controller;
--------------------
use work.vhdl_lib_pkg.debounce;
use work.vhdl_lib_pkg.one_shot;
use work.vhdl_lib_pkg.tick_extend;

entity simple_sd is
port(
	--====================
	-- System
	rst					: in  std_ulogic;
	clk					: in  std_ulogic;
	--====================
	-- drag through to SD-Card
	sd_clk			: out		std_ulogic;
	sd_cmd			: inout	std_logic;
	sd_dat			: inout	std_logic_vector(3 downto 0);
	------------------
	-- card detect
	sd_cd				: in		std_ulogic := '0';
	--====================
	-- I/O to unit above
	--%%%%%%%%%%%%%%%%
	-- control of this unit
	sleep				: in  std_ulogic := '0';
	mode				: in  sd_mode_record := sd_mode_fast;
	mode_fb			: out sd_mode_record;
	------------------
	dat_address	: in  sd_dat_address_type := (others=>'0');
	------------------
	ctrl_tick		: in  sd_tick_record := sd_tick_zero;
	fb_tick			: out sd_tick_record;
	------------------
	dat_block		: out dat_block_type;
	dat_valid		: out std_ulogic;
	dat_tick		: out std_ulogic;
	------------------
	unit_stat		: out sd_controller_stat_type
	--====================
);
end simple_sd;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture simple_sd_a of simple_sd is
	signal clk_en				: std_ulogic;
	signal ctrl_tick_en	: sd_tick_record;
	signal fb_tick_en		: sd_tick_record;
	signal dat_tick_en	: std_ulogic;
	signal unit_stat_s	: sd_controller_stat_type;
	------------------
	signal card_tick		: std_ulogic;
	signal cd_reinit		: std_ulogic;
	------------------
	type cd_state_type	is (s_reset, s_inserted, s_ejected, s_reinit);
	signal cd_state			: cd_state_type;
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	-- instantiate sd-controller
	u_sd_controller: sd_controller port map (rst=>rst, clk=>clk, clk_en_o=>clk_en, sd_clk=>sd_clk, sd_cmd=>sd_cmd, sd_dat=>sd_dat,
			sleep=>sleep, mode=>mode, mode_fb=>mode_fb, dat_address=>dat_address, ctrl_tick=>ctrl_tick_en, fb_tick=>fb_tick_en,
			dat_block=>dat_block, dat_valid=>dat_valid, dat_tick=>dat_tick_en, unit_stat=>unit_stat_s);

	-- change state to 's_no_card' if card is not inserted
	with cd_state select
		unit_stat <= unit_stat_s when s_inserted,
								 s_no_card when others;

	-- generate a tick on 'card_tick' if card is inserted
	cd_debounce:	debounce	port map (rst=>rst, clk=>clk, key=>sd_cd, tick=>card_tick);
	
	-- reinitialize card in state 's_reinit'
	with cd_state select
		cd_reinit <= '1' when s_reinit,
								 '0' when others;

	-- handle card-detect (sd_cd)
	-- reinitialize the sd-controller when card gets inserted
	p_card_detect: process(rst, clk)
	begin
		if rst = '0' then
			cd_state <= s_reset;

		elsif clk'event and clk = '1' then
			case cd_state is
				-- state after reset
				when s_reset =>
					if sd_cd = '0' then
						cd_state <= s_inserted;
					else
						cd_state <= s_ejected;
					end if;
				-- card is inserted
				when s_inserted =>
					if sd_cd = '1' then
						cd_state <= s_ejected;
					end if;
				-- card is ejected
				when s_ejected =>
					if card_tick = '1' then
						cd_state <= s_reinit;
					end if;
				-- card is reinitializing
				when s_reinit =>
					if fb_tick_en.reinit = '1' then
						cd_state <= s_inserted;
					end if;
				when others =>
					cd_state <= s_reset;
			end case;

		end if;
	end process;


	--####################################
	-- extend ticks of signal 'ctrl_tick' to the length of one 'clk_en' periode
	ctrl_tick_extend_1:	tick_extend port map (rst=>rst, clk=>clk, clk_en_y=>clk_en, a=>ctrl_tick.reinit or cd_reinit,	y=>ctrl_tick_en.reinit);
	ctrl_tick_extend_2:	tick_extend port map (rst=>rst, clk=>clk, clk_en_y=>clk_en, a=>ctrl_tick.read_single,					y=>ctrl_tick_en.read_single);
	ctrl_tick_extend_3:	tick_extend port map (rst=>rst, clk=>clk, clk_en_y=>clk_en, a=>ctrl_tick.read_multiple,				y=>ctrl_tick_en.read_multiple);
	ctrl_tick_extend_4:	tick_extend port map (rst=>rst, clk=>clk, clk_en_y=>clk_en, a=>ctrl_tick.stop_transfer,				y=>ctrl_tick_en.stop_transfer);
	-- shorten ticks to one clock-periode
	fb_one_shot_1:		one_shot port map (rst=>rst, clk=>clk, input=>fb_tick_en.reinit,				tick=>fb_tick.reinit);
	fb_one_shot_2:		one_shot port map (rst=>rst, clk=>clk, input=>fb_tick_en.read_single,		tick=>fb_tick.read_single);
	fb_one_shot_3:		one_shot port map (rst=>rst, clk=>clk, input=>fb_tick_en.read_multiple,	tick=>fb_tick.read_multiple);
	fb_one_shot_4:		one_shot port map (rst=>rst, clk=>clk, input=>fb_tick_en.stop_transfer,	tick=>fb_tick.stop_transfer);
	dat_one_shot:			one_shot port map (rst=>rst, clk=>clk, input=>dat_tick_en,							tick=>dat_tick);
	--####################################

end simple_sd_a;
