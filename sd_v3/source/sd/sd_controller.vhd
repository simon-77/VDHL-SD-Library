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
-- File:			sd_controller.vhd
-- Author:		Simon Aster
-- Created:		2017-03-24
-- Modified:	2017-06-03
-- Version:		5.3
--############################################
--############################################
-- Short Description:
--------------------
-- This unit has the logic for accessing the SD-Card.
--============================
--============================
-- Overview:
--------------------
-- This unit provides a simple front-end for reading data
-- from SD-Cards.
-- The following Types of SD-Cards are supported:
-- SCSD-Card (Standard Capacity SD)
-- HCSD-Card (High Capacity SD)
-- XCSD-Card (Extended Capacity SD)
-------
-- Allthough the front-end is very complex and multifunctional,
-- only few connections are needed:
-- 'rst' and 'clk' must be provided to this unit.
-- 'clk_en_o' is needed because all ticks correspoond to this signal.
-- 'sd_clk', 'sd_cmd' and 'sd_dat' must be directly connected to the SD-Card
-- 'dat_address' is the address of the data-block that will be read.
-- 'ctrl_tick': this record holds the ticks that activate the read process.
-- 'dat_block' is the actual data that was read.
-- 'dat_valid' indicates if data is valid (crc-checksum and read-timeout) ('1' = valid)
-- 'dat_tick' a tick indicating that the transaction has finished.
-- Even if the read timed out, there will be a tick anyway. In this case 'dat_valid' is '0'.
-------
-- NOTE:
-- The outputs 'dat_block' and 'dat_valid' are not latched and are only valid for one clk-periode (clk_en_o-periode).
-- As long as no new read or reinitialisation is started, they should stay valid.
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
-- 'mode'	record selecting the desired mode
-- 'mode_fb'	record holding current mode
------------------
-- 'dat_address'	512 byte Block-Address for read command
------------------
-- 'ctrl_tick'	ticks that control this unit (such as start read of a single block or start read of multiple blocks)
-- 'fb_tick'		gives feedback of acknowledged 'ctrl_tick's
------------------
-- 'dat_block'	a data-block holding one block of data that was read from sd-card
-- 'dat_valid'	'1' when data-block is valid
-- 'dat_tick'		a tick when a new data-block was read
------------------
-- 'unit_state'	feedback of current unit state
--====================
--		DEBUG SIGNALS
-- 'error_policy'	select behaviour in case of an error (tick is enough)
-- 'error_policy_fb' a tick indicating that the selected behaviour is executed
------------------
-- 'cmd_o'	the current command that was written to the sd-card
-- 'resp_stat_o' the response status of the current command
-- 'dat_stat_o' further details of the curent data-status
--============================
--============================
-- Sleep
------------------
-- The 'sleep' signal stops the whole unit inclusive SD-Card. The clock of the SD-Card will be turned off,
-- 'clk_en_o' is turned off as well and the whole unit is freezed. This can be done in the middle of an
-- data-transaction. The only exception is the initialisation phase. When this unit is initializing and
-- SD-Card, the 'sleep' signal will be ignored.
--============================
--============================
-- Mode
------------------
-- The record 'mode' holds two values: 'wide_bus' and 'fast':
-- * 'wide_bus':
--		If this is '1', the 4-bit sd-mode is selected in the initialisation phase. When this signal
--		is '0', the default 1-bit sd-mode is used.
-- * 'fast':
--		If this is '1', The 'sd_clk' is switched to the frequency of 'clk', when the SD-Card supports
--		High-Speed Mode. Otherwise the clock will be kept to it's initialisation frequency of 400kHz.
--		According to the SD-specification, a clock frequency of up to 50MHz is allowed. In 'fast' mode,
--		the signal 'clk' is directly connected to the sd-clock. In fast mode, the clock-frequency of the
--		of 'clk' should be not more than 50MHz. When an FPGA with a faster clock is used, the unit
--		'sd_ctrl' can be modified that in fast mode a prescaler is selected with a frequency of 50MHz like
--		the 400kHz initialisation clock.
------------------
-- In the initialisation phase, the desired mode is negotiated. 'mode_fb' reflects the actual current state.
-- Changing the mode will not result in an immediate change of the actual mode. A reset or at least a
-- reinit ('ctrl_tick.reinit') must be done for the new mode to take effekt.
------------------
-- You can set it to 'sd_mode_fast' (this constant exists in 'sd_const_pkg') to select the fastest mode.
-- When the desired mode is not available, it will not be entered and everything works as fast as possible.
--============================
--============================
-- Data-Address
------------------
-- The signal 'dat_address' is the address for the read procedures.
-- In the comand to the SD-Card, the address is byte-address in SDSC-Cards an block-address in HCSD- and XCSC-Cards.
-- The signal 'dat_address' is always the block address. Bocks are always 512 bytes large.
------------------
-- In case of SCSD-Cards, the upper 9 bits of this signal are ignored. 0x00123456 results in the same as 0xf7123456.
------------------
-- Requesting a larger block than what is available on the SD-Card is likely to result in a read timeout.
-- Requesting a block that is in the range of the card is in the responsibility of the unit above.
-- Currently there is no info about the size of the current SD-Card. This could be easily adde by reading
-- the CSD-register in the initialisation phase.
--============================
--============================
-- ctrl-ticks
------------------
-- a tick one one of these signals will start the according procedure:
-- * ctrl_tick.read_single:	read an single block of data
-- * ctrl_tick.read_multiple:	read multiple blocks of data
-- * ctrl_tick.stop_transfer:	stop the multiple-block-read procedure
-- * ctrl_tick.reinit:	make a soft reset and reinitialize the sd-card
-- A tick on the according 'fb_tick' record indicates that the action was
-- successfully started
--============================
--============================
-- DATA
------------------
-- 'dat_block' holds the data that was read.
-- 'dat_valid' is '1' when the read was successfull.
-- A tick on 'dat_tick' indicates that new data is ready.
------------------
-- These outputs are not latched and only valid for the tick of 'dat_tick'.
-- As long as no new procedure is started, the registers should hold their values.
-- When 'fb_tick' indicates that a new read procedure is started, a tick on 'dat_tick'
-- will follow always. Even when no data will arrive, the read procedure has a
-- timeout of 1s and will indicate with an tick that the read has finished. 'dat_valid' will
-- be '0' in this scenario of corse.
-- The only exception is the stop_transfer of a multiple-read procedure. In this case, the transmission
-- will be stopped immediately and no 'dat_tick' for the current data-block will be sent. But even then
-- there is a tick on 'fb_tick.stop_transfer' indicating that the read is going to be stopped.
------------------
-- For further information about the reason, why the data is not valid, the signal 'dat_stat_o' can be
-- analyzed. More information in 'const_pkg.vhd' and 'sd_ctrl.vhd'.
--============================
--============================
-- UNIT STATE
------------------
-- 'unit_stat' is the current status of this unit.
-- * s_init		the unit is initializing the SD-card => wait until the state 's_ready' is reached
-- * s_ready	the SD-card is initialized and a new data transmission can be started
-- * s_read		the SD-card is currently reading data
-- * s_error	an error occured => create a tick on 'ctrl_tick.reinit' to reinitialize the SD-card (or make a reset)
--============================
--============================
-- ERROR HANDLING
------------------
-- A tick on one of the signals of the record 'error_policy' will set the according action:
-- repeat the failed command or ignore the error.
-- A tick on 'error_policy_fb' indicates that the action was performed
------------------
-- Further information of the current error can be get by analyzing the signals
-- 'cmd_o' (holding the current command that failed) and 'resp_stat_o' (holding the status of the
-- current response).
-- Fur further information lock in 'sd_const_pkg.vhd' and 'sd_ctrl.vhd'
--############################################
--############################################

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;
--------------------
use work.vhdl_lib_pkg.ff_rs;
--------------------
use work.sd_const_pkg.all;
use work.sd_pkg.sd_transceiver;

entity sd_controller is
port(
	--====================
	-- System
	rst					: in  std_ulogic;
	clk					: in  std_ulogic;
	------------------
	clk_en_o		: out std_ulogic;
	--====================
	-- drag through to SD-Card
	sd_clk			: out		std_ulogic;
	sd_cmd			: inout	std_logic;
	sd_dat			: inout	std_logic_vector(3 downto 0);
	--====================
	-- I/O to unit above
	--%%%%%%%%%%%%%%%%
	-- control of this unit
	sleep				: in  std_ulogic := '0';
	mode				: in  sd_mode_record := sd_mode_default;
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
	unit_stat		: out sd_controller_stat_type;
	--====================
	-- debug signals
	--%%%%%%%%%%%%%%%%
	-- error policy
	error_policy		: in  sd_error_policy_record := sd_error_policy_zero;
	error_policy_fb	: out sd_error_policy_record;
	------------------
	-- additional error info of 'sd_ctrl' unit
	cmd_o				: out cmd_record;
	resp_stat_o	: out resp_stat_type;
	dat_stat_o	: out dat_stat_type
	--====================
);
end sd_controller;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture sd_controller_a of sd_controller is
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- fsm for unit
	type unit_state_type	is (s_init, s_transfer, s_error, s_read_single, s_read_multiple);
	signal unit_state, unit_state_dly	: unit_state_type;
	--==========================
	-- fsm for substates in unit_state
	type init_state_type is (s_init, s_prepare_clk, s_cmd0, s_cmd8, s_hcs, s_acmd41, s_cmd2, s_cmd3, s_rca, s_cmd7, s_acmd42, s_bus_width, s_acmd6, s_speed, s_switch_func, s_cmd6, s_switch_status, s_switch_delay, s_finish);
	signal init_state	: init_state_type;
	--==========================
	-- fsm for cmd
	type cmd_state_type		is (s_idle, s_cmd, s_cmd_wait, s_acmd, s_acmd_wait);
	signal cmd_state, cmd_state_dly		: cmd_state_type;
	-- fsm for read_single
	type read_single_state_type is (s_idle, s_cmd, s_tick, s_read);
	signal read_single_state	: read_single_state_type;
	-- fsm for read_multiple
	type read_multiple_state_type is (s_idle, s_cmd, s_read, s_stop);
	signal read_multiple_state	: read_multiple_state_type;
	-- fsm for read_status
	type read_status_state_type is (s_idle, s_tick, s_read);
	signal read_status_state	: read_status_state_type;
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- signals for sd_ctrl
	signal clk_en									: std_ulogic;
	signal sleep_sd								: std_ulogic;
	signal fast, wide_bus					: std_ulogic;
	------------------
	signal cmd										: cmd_record;
	signal cmd_start, cmd_fb			: std_ulogic;
	--
	signal resp_tick							: std_ulogic;
	signal resp										: cmd_record;
	signal csd										: csd_type;
	signal resp_stat							: resp_stat_type;
	------------------
	signal dat_start_read					: std_ulogic;
	signal dat_fb_read						: std_ulogic;
	signal dat_stop_read					: std_ulogic;
	signal dat_block_read					: dat_block_type;
	signal dat_stat_read					: dat_stat_type;
	signal dat_tick_read					: std_ulogic;
	------------------
	signal status_start_read			: std_ulogic;
	signal status_width						: natural range 1 to 512 := 512;
	signal status_fb_read					: std_ulogic;
	signal status_tick_read				: std_ulogic;
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- cmd registers
	signal cmd0, cmd2, cmd3, cmd6, cmd7, cmd8, cmd12, cmd17, cmd18, cmd55	: cmd_record;
	signal acmd6, acmd41, acmd42	: cmd_record;
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- variables used in commands
	signal rca								: std_ulogic_vector(15 downto 0);	-- used for all acmd commands and some other commands
	signal hcs								: std_ulogic;											-- set by acmd41
	signal vdd_voltage_window	: std_ulogic_vector(23 downto 0);	-- set by acmd41
	signal set_cd							: std_ulogic;											-- enable/disable internal pull-up; acmd42
	signal bus_width					: std_ulogic_vector(1 downto 0);	-- set by acmd6
	signal sw_mode						: std_ulogic;											-- mode of SWITCH_FUNC cmd6
	signal fg1								: std_ulogic_vector(3 downto 0);	-- function of function group 1 set by cmd6
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- internal registers
	signal cnt				: natural range 0 to 255; -- NOTE: consider range when used
	signal cmd_reg		: cmd_record;
	signal status_reg	: std_ulogic_vector(511 downto 0); -- Register holding status (wide-width-data)
	signal data_address_reg		: sd_dat_address_type;
	signal allow_cmd_error		: std_ulogic;
	--==========================
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	status_reg_loop: for i in 0 to 511 generate begin
		status_reg(i) <= dat_block_read(i)(0);
	end generate;


	vdd_voltage_window <= o"040" & o"00000"; -- VDD Voltage Window=3.2-3.3V, reserved bits
	set_cd <= '0';	-- Disconnect cards internal 50KOhm pull-up resistor

	-- data address = block address for HCSD and byte address for SCSD
	with hcs select
		data_address_reg <= dat_address when '1',
												dat_address(dat_address'length-10 downto 0) & "000000000" when others;

	--####################################
	--"GO_IDLE_STATE"				stuff bits
	cmd0		<= (o"00", x"00000000", R0);				-- reset card to idle state
	--"ALL_SEND_CID":				stuff bits
	cmd2		<= (o"02", x"00000000", R2);				-- Ask card to send CID
	--"SEND_RELATIVE_ADDR":	stuff bits
	cmd3		<= (o"03", x"00000000", R6);				-- Ask card to publish RCA
	--"SWITCH_FUNC":		mode,	reserved bits, function group 6-2 (f= don't change), fg1
	cmd6		<= (o"06", sw_mode & "0000000" & x"fffff" & fg1, R1);
	--"SELECT/DESELECT_CARD"
	cmd7		<= (o"07", rca & x"0000", R1b);			-- Put card into transfer state
	--"SEND_IF_COND":				reserved bits, voltage supplied, check pattern
	cmd8		<= (o"10", x"00000" & x"1" & x"aa", R7);	-- send card interface condition
	--"STOP_TRANSMISSION":	stuff bits
	cmd12		<= (o"14", x"00000000", R1b);				-- Force card to stop transmission
	--"READ_SINGLE_BLOCK"
	cmd17		<= (o"21", data_address_reg, R1);				-- Read single block from card
	--"READ_MULTIPLE_BLOCK"
	cmd18		<= (o"22", data_address_reg, R1);				-- Read multiple blocks from card
	--"APP_CMD":						RCA, stuff bits
	cmd55		<= (o"67", rca & x"0000", R1);			-- next command is acmd; 
	--====================
	--"SET_BUS_WIDTH"
	acmd6		<= (o"06", o"0000000000" & bus_width, R1); -- Define data bus width
	--"SD_SEND_OP_COND":		reserved bit, HCS, reserved bits, VDD Voltage Window
	acmd41	<= (o"51", '0' & hcs & o"00" & vdd_voltage_window, R3);	-- send host support info and receive card operating condition
	--"SET_CLR_CARD_DETECT":	stuff bits & set_cd
	acmd42	<= (o"52", o"0000000000" & '0' & set_cd, R1);	-- connect[1]/disconnect[0] the 50KOhm pull-up on CD/DAT3 of SD-Card
	--####################################


	--####################################
	-- sd-controler
	u_sd_transceiver:	sd_transceiver port map (rst=>rst, clk=>clk, sd_clk_en_o=>clk_en, sd_clk=>sd_clk, sd_cmd=>sd_cmd, sd_dat=>sd_dat, sleep=>sleep_sd, fast=>fast, wide_bus=>wide_bus,
					cmd=>cmd, cmd_start=>cmd_start, cmd_fb=>cmd_fb,
					resp=>resp, csd=>csd, resp_stat=>resp_stat, resp_tick=>resp_tick,
					dat_start_read=>dat_start_read, dat_fb_read=>dat_fb_read, dat_stop_read=>dat_stop_read,
					dat_block_read=>dat_block_read, dat_stat_read=>dat_stat_read, dat_tick_read=>dat_tick_read,
					status_start_read=>status_start_read, status_width=>status_width, status_fb_read=>status_fb_read,
					status_tick_read=>status_tick_read);
	--####################################


	--####################################
	-- direct mapped output signals
	clk_en_o		<= clk_en;
	dat_block		<= dat_block_read;
	------------------
	cmd_o				<= cmd;
	resp_stat_o <= resp_stat;
	dat_stat_o	<= dat_stat_read;
	------------------
	-- mode_fb output
	mode_fb.fast <= fast;
	mode_fb.wide_bus <= wide_bus;
	--====================
	-- other output signals
	with dat_stat_read select
		dat_valid <= '1' when dat_stat_valid,
								 '0' when others;
	------------------
	-- Suppress dat_tick when unit is not reading data
	dat_tick <= dat_tick_read when (unit_state = s_read_single)		and (read_single_state	 = s_read) else
							dat_tick_read when (unit_state = s_read_multiple) and (read_multiple_state = s_read) else
							'0';
	------------------
	-- output 'unit_stat': feedback of current state
	with unit_state select
		unit_stat <= s_init		when s_init,
								 s_ready	when s_transfer,
								 s_read		when s_read_single | s_read_multiple,
								 s_error	when others;
	--####################################

	--####################################
	-- signals for 'sd_ctrl' unit
	------------------
	-- Don't sleep during initialization.
	-- E.g. ACMD41 does not allow complete clock-shutdown
	with unit_state select
		sleep_sd <= '0' when s_init,
								sleep when others;
	------------------
	with cmd_state select
		cmd <= cmd55		when s_acmd | s_acmd_wait,
					 cmd_reg	when s_cmd	| s_cmd_wait,
					 cmd0			when others;
	------------------
	with cmd_state select
		cmd_start <=		'1' when s_cmd,
										'1' when s_acmd,
										'0' when others;
	------------------
	dat_start_read <= '1' when read_single_state	 = s_tick else
										'1' when read_multiple_state = s_read else
										'0';
	------------------
	dat_stop_read <=	'1' when read_multiple_state = s_stop else
										'0';
	------------------
	status_start_read <= '1' when read_status_state = s_tick else
											 '0';
	--####################################



	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
	p_sd_controller: process(rst, clk)
		variable prev_unit_state		: unit_state_type;
		variable prev_cmd_type			: cmd_state_type;
		----------------
	begin
	--####################################
	if rst = '0' then
		--==========================
		-- sd_ctrl
		fast			<= '0';
		wide_bus	<= '0';
		status_width <= 512;
		-- outputs
		fb_tick					<= sd_tick_zero;
		error_policy_fb <= sd_error_policy_zero;
		--==========================
		-- states
		unit_state				<= s_init;
		unit_state_dly		<= s_init;
		prev_unit_state		:= s_init;
		cmd_state					<= s_idle;
		cmd_state_dly			<= s_idle;
		prev_cmd_type			:= s_idle;
	------------------
		init_state					<= s_init;
		read_single_state		<= s_idle;
		read_multiple_state <= s_idle;
		read_status_state		<= s_idle;
		--==========================
		-- internal signals for cmds
		rca				<= (others=>'0');
		hcs				<= '0';
		bus_width <= (others=>'0');
		sw_mode		<= '0';
		fg1				<= (others=>'0');
		-- internal registers
		cnt				<= 0;
		cmd_reg		<= cmd0;
		allow_cmd_error <= '0';

	--####################################
	elsif clk'event and clk = '1' then
		if clk_en = '1' then

			--==========================
			-- reset signals and set them further down if set
			fb_tick <= sd_tick_zero;
			error_policy_fb <= sd_error_policy_zero;
			-- delay states
			unit_state_dly	<= unit_state;
			cmd_state_dly		<= cmd_state;
			-- count one up; reset to 0 in state if needed
			cnt <= cnt + 1;

			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for cmd state

			-- when 'cmd_state' switched from idle state, save cmd-type
			if (cmd_state_dly /= cmd_state) and (cmd_state_dly = s_idle) then
				prev_cmd_type := cmd_state;
			end if;

			case cmd_state is
				--§§§§§§§§§§§§§§§§§§§§
				-- write cmd55: next cmd is an acmd
				when s_acmd =>
					if cmd_fb = '1' then
						cmd_state <= s_acmd_wait;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- wait for cmd55 to finish
				when s_acmd_wait =>
					if resp_tick = '1' then
						if resp_stat = resp_stat_valid then
							cmd_state <= s_cmd;
						else
							unit_state <= s_error;
						end if;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- write command of cmd_reg
				when s_cmd =>
					if cmd_fb = '1' then
						cmd_state <= s_cmd_wait;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- wait for current cmd to finish
				when s_cmd_wait =>
					if resp_tick = '1' then
						if (resp_stat = resp_stat_valid) or (allow_cmd_error = '1') then
							cmd_state <= s_idle;
						else
							unit_state <= s_error;
						end if;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				when s_idle =>
					allow_cmd_error <= '0';
					-- NOTE: setting 'allow_cmd_error' to '1' must be done further downe
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				when others =>
					cmd_state <= s_idle;
			end case;


			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for unit state

			-- save unit_state before it got 's_error'
			if unit_state /= s_error then
				prev_unit_state := unit_state;
			end if;

			case unit_state is
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- error
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- an error occured, act as given by 'error_policy'
				when s_error =>
					if error_policy.retry = '1' then
						error_policy_fb.retry <= '1';
						cmd_state			<= prev_cmd_type;
						unit_state		<= prev_unit_state;
					elsif error_policy.ignore = '1' then
						error_policy_fb.ignore <= '1';
						cmd_state			<= s_idle;
						unit_state		<= prev_unit_state;
					end if;
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- init
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- initialize SD-Card
				when s_init =>
					if cmd_state = s_idle then
						case init_state is
							--§§§§§§§§§§§§§§§§§§§§
							-- reset all signals
							when s_init =>
								-- sd_ctrl
								fast			<= '0';
								wide_bus	<= '0';
								-- internal signals
								rca				<= (others=>'0');
								hcs				<= '0';
								bus_width	<= (others=>'0');
								sw_mode		<= '0';
								fg1				<= (others=>'0');
								--------------
								cnt				<= 0;
								cmd_reg 	<= cmd0;
								allow_cmd_error <= '0';
								--------------
								cmd_state <= s_idle;
								init_state <= s_prepare_clk;
							--§§§§§§§§§§§§§§§§§§§§
							-- initialize card with 74 clk-cycles before the first command
							when s_prepare_clk =>
								if cnt = 74 then
									-- write cmd0 to SD-Card: reset
									cmd_reg 	<= cmd0;
									cmd_state <= s_cmd;
									init_state <= s_cmd0;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- write cmd8: send interface condition
							when s_cmd0 =>
								cmd_reg		<= cmd8;
								cmd_state <= s_cmd;
								init_state <= s_cmd8;
								-- expect error: SCSD-Card don't respond to cmd8
								allow_cmd_error <= '1';
							--§§§§§§§§§§§§§§§§§§§§
							-- select if host should support SDHC (hcs)
							when s_cmd8 =>
								if resp_stat = resp_stat_valid then
									-- when card responded to cmd8, card is HCSD
									hcs <= '1';
									init_state <= s_hcs;
								elsif resp_stat(e_timeout) = '1' then
									-- when card did'nt respond to cmd8, card is SCSD
									hcs <= '0';
									init_state <= s_hcs;
								else
									unit_state <= s_error;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- write acmd41 (set hcs)
							when s_hcs =>
								cmd_reg		<= acmd41;
								cmd_state <= s_acmd;
								init_state <= s_acmd41;
							--§§§§§§§§§§§§§§§§§§§§
							-- wait until card is ready
							when s_acmd41 =>
								if resp.arg(31) = '0' then
									-- card is busy, send acmd41 again
									cmd_reg		<= acmd41;
									cmd_state <= s_acmd;
								else
									-- card is read, send cmd2: ask card to send cid
									cmd_reg		<= cmd2;
									cmd_state <= s_cmd;
									init_state <= s_cmd2;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- write cmd3: get relative card address (rca)
							when s_cmd2 =>
								cmd_reg		<= cmd3;
								cmd_state <= s_cmd;
								init_state <= s_cmd3;
							--§§§§§§§§§§§§§§§§§§§§
							-- save rca
							when s_cmd3 =>
								rca <= resp.arg(31 downto 16);
								init_state <= s_rca;
							--§§§§§§§§§§§§§§§§§§§§
							-- write cmd7: swtich to 'transfer' state
							when s_rca =>
								cmd_reg	<= cmd7;
								cmd_state <= s_cmd;
								init_state <= s_cmd7;
							--§§§§§§§§§§§§§§§§§§§§
							-- write acmd42: disable cards internal pull-up
							when s_cmd7 =>
								cmd_reg <= acmd42;
								cmd_state <= s_acmd;
								init_state <= s_acmd42;
							--§§§§§§§§§§§§§§§§§§§§
							-- request 4-bit sd-bus mode when desired
							when s_acmd42 =>
								if mode.wide_bus = '1' then
									bus_width <= "10";
									init_state <= s_bus_width;
								else
									init_state <= s_speed;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- write acmd6: set bus-width
							when s_bus_width =>
								cmd_reg		<= acmd6;
								cmd_state <= s_acmd;
								init_state <= s_acmd6;
							--§§§§§§§§§§§§§§§§§§§§
							-- select 4-bit mode
							when s_acmd6 =>
								wide_bus <= '1';
								init_state <= s_speed;
							--§§§§§§§§§§§§§§§§§§§§
							-- request High-Speed mode when desired
							when s_speed =>
								if mode.fast = '1' then
									sw_mode <= '1'; -- switch function = mode 1 : set function
									fg1 <= x"1";		-- function group 1 = 0x1: High-Speed mode
									init_state <= s_switch_func;
								else
									init_state <= s_finish;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- write cmd6: switch function (switch speed mode)
							when s_switch_func =>
								cmd_reg <= cmd6;
								cmd_state <= s_cmd;
								init_state <= s_cmd6;
								allow_cmd_error <= '1';
							--§§§§§§§§§§§§§§§§§§§§
							-- when card responds to cmd6: read 'switch function status'
							when s_cmd6 =>
								if resp_stat = resp_stat_valid then
									-- read a single 512-bit block: response of cmd6
									status_width <= 512;
									read_status_state <= s_tick;
									init_state <= s_switch_status;
								else
									init_state <= s_finish;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- check switch function status if switch to High-Speed mode was successfull
							when s_switch_status =>
								if read_status_state = s_idle then
									if dat_stat_read /= dat_stat_valid then
										init_state <= s_finish;
									elsif status_reg(379 downto 376) = x"1" then
										init_state <= s_switch_delay;
										cnt <= 0;
									end if;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- delay switch of clk-frequency by 8 clk-cylces
							when s_switch_delay =>
								if cnt = 8 then
									fast <= '1';
									init_state <= s_finish;
								end if;
							--§§§§§§§§§§§§§§§§§§§§
							-- finish initialisation and go to transfer state
							when s_finish =>
								unit_state <= s_transfer;
							--§§§§§§§§§§§§§§§§§§§§
							when others =>
								init_state <= s_init;
						end case;
					end if;

				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- transfer
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- SD-Card is in transfer state: read operations can be started
				when s_transfer =>
					-- read a single data block
					if ctrl_tick.read_single = '1' then
						if read_single_state = s_idle then
							fb_tick.read_single <= '1';
							unit_state <= s_read_single;
							read_single_state <= s_cmd;
							cmd_reg <= cmd17;
							cmd_state <= s_cmd;
						end if;
					-- read multiple data blocks
					elsif ctrl_tick.read_multiple = '1' then
						if read_multiple_state = s_idle then
							fb_tick.read_multiple <= '1';
							unit_state <= s_read_multiple;
							read_multiple_state <= s_cmd;
							cmd_reg <= cmd18;
							cmd_state <= s_cmd;
						end if;
					end if;

				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- read single
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- Read a single data block from SD-Card
				when s_read_single =>
					-- go back to idle if transfer finished
					if read_single_state = s_idle then
						unit_state <= s_transfer;
					end if;

				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- read multiple
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				-- Read multiple blocks from SD-Card
				when s_read_multiple =>
					-- go back to idle if transfer finished
					if read_multiple_state = s_idle then
						unit_state <= s_transfer;
					end if;

				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				when others=>
					unit_state <= s_init;
			end case;


			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for read_single state

			case read_single_state is
				--§§§§§§§§§§§§§§§§§§§§
				-- idle: nothing to do
				when s_idle =>
				--§§§§§§§§§§§§§§§§§§§§
				-- wait for cmd17 (read single block) to finish
				when s_cmd =>
					if cmd_state = s_idle then
						read_single_state <= s_tick;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- start listening for a new incoming byte
				when s_tick =>
					if dat_fb_read = '1' then
						read_single_state <= s_read;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- wait for block read operation to finish
				when s_read =>
					if dat_tick_read = '1' then
						read_single_state <= s_idle;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				when others =>
					read_single_state <= s_idle;
			end case;

			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for read_multiple state

			case read_multiple_state is
				--§§§§§§§§§§§§§§§§§§§§
				-- idle: nothing to do
				when s_idle =>
				--§§§§§§§§§§§§§§§§§§§§
				-- wait for cmd18 (read multiple blocks) to finish
				when s_cmd =>
					if cmd_state = s_idle then
						read_multiple_state <= s_read;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- read incoming data until interupted
				when s_read =>
					if ctrl_tick.stop_transfer = '1' then
						fb_tick.stop_transfer <= '1';
						read_multiple_state <= s_stop;
						cmd_reg <= cmd12; -- cmd12: stop transfer
						cmd_state <= s_cmd;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- stop sd_ctrl unit reading data
				when s_stop =>
					-- wait for cmd12 to finish
					if cmd_state = s_idle then
						read_multiple_state <= s_idle;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				when others =>
					read_multiple_state <= s_idle;
			end case;

			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			-- fsm for read_status state

			case read_status_state is
				--§§§§§§§§§§§§§§§§§§§§
				-- idle: nothing to do
				when s_idle =>
				--§§§§§§§§§§§§§§§§§§§§
				-- start listening for new status
				when s_tick =>
					if status_fb_read = '1' then
						read_status_state <= s_read;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				-- wait until read is finished
				when s_read =>
					if status_tick_read = '1' then
						read_status_state <= s_idle;
					end if;
				--§§§§§§§§§§§§§§§§§§§§
				when others =>
					read_status_state <= s_idle;
			end case;

			--8888888888888888888888888888888888888888888
			--8888888888888888888888888888888888888888888
			-- reinitialise SD-Card
			-- this makes a soft reset of the card and this unit
			if ctrl_tick.reinit = '1' then
				fb_tick.reinit <= '1';
				unit_state <= s_init;
				init_state <= s_init;
				read_single_state <= s_idle;
				read_multiple_state <= s_idle;
				read_status_state <= s_idle;
				if unit_state = s_error then
					cmd_state <= s_idle;
				end if;
			end if;
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		end if;
	end if;
	--####################################
	end process;
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
end sd_controller_a;
