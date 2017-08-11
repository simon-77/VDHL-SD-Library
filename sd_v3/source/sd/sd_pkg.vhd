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
----------------------------------------------
-- Library:		sd
-- File:			sd_pkg.vhd
-- Author:		Simon Aster
-- Created:		2017-03
-- Modified:	2017-06-02
-- Version:		3.3
----------------------------------------------
-- Description:
-- This package is containing all component
-- from the library 'sd'
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.de0_nano_const_pkg.all;
use work.sd_const_pkg.all;

package sd_pkg is
--&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
	--===========================================
	component crc
	generic(
		length			: natural;
		polynomial	: std_ulogic_vector
	);
	port(
		rst				: in  std_ulogic;
		clk				: in  std_ulogic;
		clk_en		: in  std_ulogic := '1';
		------------------
		rst_crc			: in  std_ulogic := '0';
		en_crc			: in  std_ulogic := '1';
		shift_out		: in  std_ulogic := '0';
		dat_in			: in  std_ulogic;
		dat_out			: out std_ulogic
	);
	end component;
	--===========================================
	component sd_controller
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
	end component;
	--===========================================
	component sd_transceiver
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
	end component;
	--===========================================
	component simple_sd
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
	end component;
	--===========================================
	--&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
end sd_pkg;
