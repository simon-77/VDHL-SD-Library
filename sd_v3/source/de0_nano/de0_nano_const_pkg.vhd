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
-- File:	de0_nano_const_pkg.vhd
-- Author:	Simon Aster
-- Date:	June 12, 2016
-- Version:	1
----------------------------------------------
-- Description:
-- Package with constants for DE0-Nano 
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;

package de0_nano_const_pkg is
	constant CLK_FREQ : natural := 50e6;

	constant RST_ACTIVE : std_ulogic := '0';
	constant CLK_ACTIVE : std_ulogic := '1';
	constant CLK_EN_ACTIVE : std_ulogic := '1';
	constant TICK_ACTIVE : std_ulogic := '1';
end de0_nano_const_pkg;
