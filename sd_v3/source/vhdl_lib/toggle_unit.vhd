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
-- File:			toggle.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2016-06-12
-- Version:		3.2
----------------------------------------------
-- Description:
-- Whenever a positive clk-edge is detected while clk_en is '1',
-- the toggle signal will change its state. It is set to '0'
-- during a low rst signal.
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;



entity toggle_unit is
	port(
	rst			: in  std_ulogic;
	clk			: in  std_ulogic;
	clk_en	: in  std_ulogic := '1';
	toggle	: out std_ulogic
);
end toggle_unit;

architecture toggle_unit_a of toggle_unit is
	signal s_toggle : std_ulogic;
begin

	toggle <= s_toggle;

	toggle_process : process(rst, clk)
	begin
		if rst = '0' then
			s_toggle <= '0';

		elsif clk'event and clk = '1' then
			
			if clk_en = '1' then
				s_toggle <= not s_toggle;
			end if;

		end if;
	end process;

end toggle_unit_a;
