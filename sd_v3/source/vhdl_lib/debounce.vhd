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
-- File:			debounce.vhd
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2017-03-2
-- Version:		4.2
----------------------------------------------
-- Description:
-- This unit debounces a key by software. After
-- a clear transition from '1' to '0' a tick is 
-- generated. 'n' is the number of clk-cycles
-- key has to be in one state statically until
-- the transition is recogniced. By default key
-- must be '0' for 1 ms until a tick is generated.
-- 'debounced' is a debounced version of 'key' (no tick).
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.de0_nano_const_pkg.all;


entity debounce is
generic(n : natural := CLK_FREQ/1e3);
port(
	rst					: in  std_ulogic;
	clk					: in  std_ulogic;
	clk_en			: in  std_ulogic := '1';
	key					: in  std_ulogic;
	tick				: out std_ulogic;
	debounced		: out std_ulogic
);
end debounce;


architecture debounce_a of debounce is
	signal val_s		: natural range 0 to n;
	signal last			: std_ulogic;
	signal s_tick		: std_ulogic;
begin

	tick <= s_tick;
	debounced <= last;

	debounce_process: process(rst, clk, key)
	begin
		if rst = '0' then
			s_tick <= '0';
			val_s <= 0;
			last <= key;
		else
			--#############################
			--#############################
			if last = key then
				val_s <= 0;

			elsif clk'event and clk = '1' then
				if clk_en = '1' then
					--======================
					case val_s is
						when n =>
							---------------
							if key = '0' then
								s_tick <= '1';
							end if;
							last <= key;
							val_s <= 0;
							---------------
						when others =>
							val_s <= val_s + 1;
					end case;
					--======================

				end if;
			end if;

			--#############################
			--#############################
			if clk'event and clk = '1' then
				if clk_en = '1' then
					--======================
					if s_tick = '1' then
						s_tick <= '0';
					end if;
					--======================
				end if;
			end if;

		end if;
	end process;
end debounce_a;
