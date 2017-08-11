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
-- File:			sd_const_pkg.vhd
-- Author:		Simon Aster
-- Created:		2017-03
-- Modified:	2017-06-02
-- Version:		4.4
----------------------------------------------
-- Description:
-- This package is containing all component
-- from the library 'sd'
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.de0_nano_const_pkg.all;

package sd_const_pkg is
	--&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
	--===========================================
	-- polynomial and length for crc7 and crc16 chechsum
	constant crc7_pol		: std_ulogic_vector := "0001001";
	constant crc7_len		: natural := 7;
	constant crc16_pol	: std_ulogic_vector := "0001000000100001";
	constant crc16_len	: natural := 16;
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- transceiver
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- expected response
	type resp_type is (R0, R1, R1b, R2, R3, R6, R7); --R0: No response (CMD0)
	------------------
	type cmd_record is record
		index	: std_ulogic_vector(5 downto 0);
		arg		: std_ulogic_vector(31 downto 0);
		resp	: resp_type;
	end record cmd_record;
	------------------
	-- csd (Card Specific Data) and cid (Card IDentification) register
	subtype csd_type is std_ulogic_vector(127 downto 0);
	--===========================================
	--===========================================
	-- response status
	subtype resp_stat_type is std_ulogic_vector(4 downto 0);
	constant resp_stat_valid	: resp_stat_type := (others=>'0');
	------------------
	-- according bit is set to '1'
	constant e_timeout	: natural := 0; -- no response received
	constant e_crc			: natural := 1; -- crc of response is wrong
	constant e_common		: natural := 2; -- some well-known bits are wrong
	constant e_busy			: natural := 3; -- busy timeout: card is still busy
	constant e_unknown	: natural := 4; -- unknow error (invalid program path was taken)
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- dat
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	constant blocklen	: natural := 512;
	subtype byte_type is std_ulogic_vector(7 downto 0);
	------------------
	type dat_block_type is array (blocklen-1 downto 0) of byte_type;
	--===========================================
	--===========================================
	-- data status
	subtype dat_stat_type is std_ulogic_vector(1 downto 0);
	constant dat_stat_valid	: dat_stat_type := (others=>'0');
	------------------
	-- according bit is set to '1'
	-- constants e_timeout := 0 & e_crc := 1 are used from 'resp_stat_type'
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	-- controller
	--%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	type sd_controller_stat_type is (s_init, s_ready, s_read, s_error, s_no_card);
	------------------
	subtype sd_dat_address_type is std_ulogic_vector(31 downto 0);
	--===========================================
	--===========================================
	type sd_tick_record is record
		reinit				: std_ulogic;
		read_single		: std_ulogic;
		read_multiple	: std_ulogic;
		stop_transfer	: std_ulogic;
	end record;
	constant sd_tick_zero	: sd_tick_record := (others=>'0');
	--===========================================
	--===========================================
	type sd_mode_record is record
		fast			: std_ulogic;
		wide_bus	: std_ulogic;
	end record;
	constant sd_mode_default	: sd_mode_record := (others=>'0');
	constant sd_mode_fast			: sd_mode_record := (others=>'1');
	--===========================================
	--===========================================
	type sd_error_policy_record is record
		retry		: std_ulogic;
		ignore	: std_ulogic;
	end record;
	constant sd_error_policy_zero	: sd_error_policy_record := (others=>'0');
	--&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
end sd_const_pkg;
