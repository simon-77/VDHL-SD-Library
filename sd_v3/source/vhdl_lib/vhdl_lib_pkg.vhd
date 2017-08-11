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
-- File:			vhdl_lib_pkg
-- Author:		Simon Aster
-- Created:		2016
-- Modified:	2017-06-02
-- Version:		6.4
----------------------------------------------
-- Description:
-- This package is containing all component
-- from the library 'vhdl_lib'
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.de0_nano_const_pkg.all;

package vhdl_lib_pkg is
--&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
	component count_bin
	generic(
		bits		: natural
	);
	port(
		rst			: in  std_ulogic;
		clk			: in  std_ulogic;
		clk_en	: in  std_ulogic := '1';
		zero		: in  std_ulogic := '0';
		up			: in  std_ulogic := '0';
		down		: in  std_ulogic := '0';
		cnt			: out std_ulogic_vector(bits-1 downto 0)
	);
	end component;
	--===========================================
	component count_int
	generic(
		max			: integer;
		min			: integer := 0
	);
	port(
		rst			: in  std_ulogic;
		clk			: in  std_ulogic;
		clk_en	: in  std_ulogic := '1';
		set_min	: in  std_ulogic := '0';
		set_max	: in  std_ulogic := '0';
		up			: in  std_ulogic := '0';
		down		: in  std_ulogic := '0';
		cnt			: out integer range min to max-1;
		ofl			: out std_ulogic;
		ufl			: out std_ulogic
	);
	end component;
	--===========================================
	component debounce
	generic(n : natural := CLK_FREQ/1e3);
	port(
		rst					: in  std_ulogic;
		clk					: in  std_ulogic;
		clk_en			: in  std_ulogic := '1';
		key					: in  std_ulogic;
		tick				: out std_ulogic;
		debounced		: out std_ulogic
	);
	end component;
	--===========================================
	component ff_rs
	port(
		rst			: in  std_ulogic;
		clk			: in  std_ulogic;
		clk_en	: in  std_ulogic := '1';
		s				: in  std_ulogic;
		r				: in  std_ulogic;
		q				: out std_ulogic
	);
	end component;
	--===========================================
	component one_shot
	port(
		rst		: in  std_ulogic;
		clk		: in  std_ulogic;
		input	: in  std_ulogic;
		tick	: out std_ulogic
	);
	end component;
	--===========================================
	component prescaler
	generic(
		divisor		: natural;		-- f(clk_en) = f(clk) / divisor
		phase			: natural := 0	-- (optional) phase of clk_en [1/100]
	);
	port(
		rst				: in  std_ulogic;
		clk				: in  std_ulogic;
		i_clk_en	: in  std_ulogic := '1';
		o_clk_en	: out std_ulogic
	);
	end component;
	--===========================================
	component pwm_unit
	generic(
		max			: natural;		-- exclusive maximum for 'pwm_val'
		phase		: natural := 0	-- (optional) phase of the pwm-signal [1/100]
	);
	port(
		rst			: in  std_ulogic;
		clk			: in  std_ulogic;
		clk_en 	: in  std_ulogic;
		pwm_val	: in  natural range 0 to max-1;
		pwm_out	: out std_ulogic
	);	-- f(pwm_out) = f(clk_en) / (max-1)
	end component;
	--===========================================
	component reset_unit
	generic(n : natural := CLK_FREQ/10);	-- default rst-time: 1/10s = 100ms
	port(
		i_rst		: in  std_ulogic := '1';
		o_rst		: out std_ulogic;
		clk			: in  std_ulogic
	);
	end component;
	--===========================================
	component rotary
	generic(dir		: std_ulogic := '0');
	port(
		rst					: in  std_ulogic;
		clk					: in  std_ulogic;
		clk_en			: in  std_ulogic := '1';
		a						: in  std_ulogic;
		b						: in  std_ulogic;
		tick_cw			: out std_ulogic;
		tick_ccw		: out std_ulogic
	);
	end component;
	--===========================================
	component sweep_unit
	generic(max : natural);	-- exclusive maximum of 'sweep_val'
	port(
		rst					: in  std_ulogic;
		clk					: in  std_ulogic;
		clk_en			: in  std_ulogic := '1';
		sweep_val 	: out natural range 0 to max-1
	);
	end component;
	--===========================================
	component tick_extend
	port(
		rst				: in  std_ulogic;
		clk				: in  std_ulogic;
		------------------
		clk_en_y	: in  std_ulogic;
		a					: in  std_ulogic;
		y					: out std_ulogic
	);
	end component;
	--===========================================
	component toggle_unit
		port(
		rst			: in  std_ulogic;
		clk			: in  std_ulogic;
		clk_en	: in  std_ulogic := '1';
		toggle	: out std_ulogic
	);
	end component;
	--===========================================
	--&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
end vhdl_lib_pkg;
