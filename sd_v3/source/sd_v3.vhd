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
-- Project:		sd_v3
-- File:			sd_v3.vhd
-- Author:		Simon Aster
-- Created:		2017-05-19
-- Modified:	2017-05-19
-- Version:		1
----------------------------------------------
-- Description:
-- 
----------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library work;
use work.de0_nano_const_pkg.all;

-- vhdl_lib
use work.vhdl_lib_pkg.count_bin;
use work.vhdl_lib_pkg.count_int;
use work.vhdl_lib_pkg.debounce;
use work.vhdl_lib_pkg.ff_rs;
use work.vhdl_lib_pkg.one_shot;
use work.vhdl_lib_pkg.prescaler;
use work.vhdl_lib_pkg.pwm_unit;
use work.vhdl_lib_pkg.reset_unit;
use work.vhdl_lib_pkg.rotary;
use work.vhdl_lib_pkg.sweep_unit;
use work.vhdl_lib_pkg.tick_extend;
use work.vhdl_lib_pkg.toggle_unit;

-- sd
use work.sd_const_pkg.all;
use work.sd_pkg.simple_sd;


entity sd_v3 is
	port(
	clk			: in  std_ulogic;
	--	===========================================
	-- Connections to SD-Card Shield
	--	===========================================
	sd_clk	: out		std_ulogic;
	sd_cmd	: inout std_logic;
	sd_dat	: inout std_logic_vector(3 downto 0);	
	------------------
	sd_wp		: in std_ulogic;
	sd_cd		: in std_ulogic;
	------------------
	ledg		: out std_ulogic_vector(7 downto 0);
	ledr		: out std_ulogic_vector(3 downto 0);
	pb			: in std_ulogic_vector(3 downto 0);
	--	===========================================
	--	===========================================
	-- std IO for debugging purpose
	key			: in  std_ulogic_vector(1 downto 0);
	sw			: in  std_ulogic_vector(3 downto 0);
	led			: out std_ulogic_vector(7 downto 0)
);
end sd_v3;

--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$

architecture sd_v3_a of sd_v3 is
	signal rst : std_ulogic;
	-- =================================
	signal pb_tick		: std_ulogic_vector(pb'length-1 downto 0);
	-- =================================
	signal sleep								: std_ulogic := '0';
	signal mode, mode_fb				: sd_mode_record;
	signal dat_address					: sd_dat_address_type := (others=>'0');
	signal ctrl_tick, fb_tick		: sd_tick_record;
	signal dat_block						: dat_block_type;
	signal dat_valid, dat_tick	: std_ulogic;
	signal unit_stat						: sd_controller_stat_type;
	-- =================================
	signal byte		: std_ulogic_vector(7 downto 0);
	signal valid	: std_ulogic;
--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
begin

	--=====================================================
	power_on_reset:				reset_unit generic map (n=>CLK_FREQ/10) port map (o_rst=>rst, i_rst=>pb(0), clk=>clk);
	--=====================================================
	debounce_pbs:	for i in 0 to pb'length-1 generate begin
		debounce_pbs_i:	debounce	port map (rst=>rst, clk=>clk, key=>pb(i), tick=>pb_tick(i));
	end generate;
	--=====================================================

	u_simple_sd:	simple_sd port map (rst=>rst, clk=>clk, sd_clk=>sd_clk, sd_cmd=>sd_cmd, sd_dat=>sd_dat, sd_cd=>sd_cd,
									sleep=>sleep, mode=>mode, mode_fb=>mode_fb, dat_address=>dat_address, ctrl_tick=>ctrl_tick, fb_tick=>fb_tick,
									dat_block=>dat_block, dat_valid=>dat_valid, dat_tick=>dat_tick, unit_stat=>unit_stat);

	add_count:		count_bin generic map (bits=>32) port map (rst=>rst, clk=>clk, up=>dat_tick, cnt=>dat_address);
	led <= dat_address(7 downto 0);

	mode.fast <= sw(0);
	mode.wide_bus <= sw(1);

	ctrl_tick.read_single		<= pb_tick(1);
	--sleep <= not pb(1);
	ctrl_tick.read_multiple	<= pb_tick(2);
	ctrl_tick.stop_transfer	<= pb_tick(3);

	ledr(0) <= mode_fb.fast;
	ledr(1) <= mode_fb.wide_bus;
	ledr(2) <= valid;
	with unit_stat select
		ledr(3) <= '1' when s_ready,
							 '0' when others;
	ledg <= byte;

	d_ff: process(rst, clk)
	begin
		if rst = '0' then
			byte <= (others=>'0');
			valid <= '1';
		elsif clk'event and clk = '1' then
			if dat_tick = '1' then
				byte <= dat_block(0);
				valid <= dat_valid and valid;
			end if;
		end if;
	end process;
--===============================================
-- templates: library 'vhdl_lib'
--	u_count_bin:		count_bin generic map (bits=>) port map (rst=>rst, clk=>clk, up=>, down=>, cnt=>);
--	u_count_int:		count_int generic map (max=>) port map (rst=>rst, clk=>clk, up=>, down=>, cnt=>);
--	u_debounce:			debounce port map (rst=>rst, clk=>clk, key=>, tick=>);
--	u_ff_rs:				ff_rs port map (rst=>rst, clk=>clk, s=>, r=>, q=>);
--	u_one_shot:			one_shot port map (rst=>rst, clk=>clk, input=>, tick=>);
--	u_prescaler:		prescaler generic map (divisor=>) port map (rst=>rst, clk=>clk, o_clk_en=>);
--	u_pwm_unit:			pwm_unit generic map (max=>) port map (rst=>rst, clk=>clk, clk_en=>, pwm_val=>, pwm_out=>);
--	u_rotary:				rotary port map (rst=>rst, clk=>clk, a=>, b=>, tick_cw=>, tick_ccw=>);
--	u_sweep_unit:		sweep_unit generic map (max=>) port map (rst=>rst, clk=>clk, clk_en=>, sweep_val=>);
--	u_tick_extend:	tick_extend port map (rst=>rst, clk=>clk, clk_en_y=>, a=>, y=>);
--	u_toggle_unit:	toggle_unit port map (rst=>rst, clk=>clk, clk_en=>, toggle=>);
--===============================================
end sd_v3_a;
