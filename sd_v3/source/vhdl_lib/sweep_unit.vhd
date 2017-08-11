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
-- Library:		vhdl_lib
-- File:			sweep.vhd
-- Author:		Aster Simon
-- Created:		2016
-- Modified:	2016-06-12
-- Version:		4.2
----------------------------------------------
-- Description:
-- This unit sweeps the signal 'sweep_val'
-- between 0 and max-1. When the value is either
-- 0 or max-1 the direction will change. The value
-- increases or decreases by one every positive 
-- clk edge when clk_en is high.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;



entity sweep_unit is
generic(max : natural);	-- exclusive maximum of 'sweep_val'
port(
	rst				: in  std_ulogic;
	clk				: in  std_ulogic;
	clk_en		: in  std_ulogic := '1';
	sweep_val	: out natural range 0 to max-1
);
end sweep_unit;

architecture sweep_unit_a of sweep_unit is
begin
	

	sweep_process : process(rst, clk)
		variable val : natural range 0 to max-1;
		variable dir : std_ulogic;
	begin
	
	if rst = '0' then
		val := 0;
		dir := '0';

	elsif clk'event and clk = '1' then
		if clk_en = '1' then
			
			case dir is
				when '0'	=> val := val + 1;
				when others => val := val - 1;
			end case;

			case val is
				when 0		=> dir := '0';
				when max-1	=> dir := '1';
				when others	=> dir := dir;
			end case;

			sweep_val <= val;

		end if;
	end if;
	end process;
	
end sweep_unit_a;
