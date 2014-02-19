--------------------------------------------------------------------------------
-- Test Pattern Matcher from top

-- Jon Turner, 12/2013

-- Modified by Likai Yan 02/2014

-- Modification: I have added a few test as instructed in the comment. The circuit
-- can be tested for: 1. three repeated b and all pass, 2.recognize pattern a, but failed,
-- 3. recognize pattern ab{n}, but failed to proceed. 4. recognize pattern ac, but failed to proceed. 
-- 5. a few other tests with different num of a and b 
--------------------------------------------------------------------------------
LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use work.commonDefs.all;
 
entity testTop is end testTop;
 
architecture behavior of testTop is 
 
-- Component Declaration for the Unit Under Test (UUT)

COMPONENT top
PORT(
	 clk : IN  std_logic;
	 btn : IN  std_logic_vector(3 downto 0);
	 knob : IN  std_logic_vector(2 downto 0);
	 swt : IN  std_logic_vector(3 downto 0);
	 led : OUT  std_logic_vector(7 downto 0);
	 lcd : OUT  lcdSigs
	);
END COMPONENT;


--Inputs
signal clk : std_logic := '0';
signal btn : std_logic_vector(3 downto 0) := (others => '0');
signal knob : std_logic_vector(2 downto 0) := (others => '0');
signal swt : std_logic_vector(3 downto 0) := (others => '0');

 --Outputs
signal led : std_logic_vector(7 downto 0);
signal lcd : lcdSigs;

-- Clock period definitions
constant clk_period : time := 20 ns;
constant pause : time := 5*clk_period;

signal rot: std_logic_vector(1 downto 0) := "00";
signal press: std_logic := '0';

-- These signals are used in the procedures defined below.
signal inSym, repCount : nibble := x"0";
 
BEGIN
	knob(0) <= press; knob(2 downto 1) <= rot;
	
	-- Instantiate the Unit Under Test (UUT)
	uut: top PORT MAP (clk, btn, knob, swt, led, lcd);

	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0'; wait for clk_period/2;
		clk <= '1'; wait for clk_period/2;
	end process;

	-- Stimulus process
	stim_proc: process

	-- The procedures below are designed to make it easier to specify
	-- your test input. Take a few minutes to make sure you understand
	-- how they work. Ask questions if you're not sure. Then, use them
	-- to specify your tests.

	-- rotate the knob to the right cnt times
	procedure rrot(cnt: in integer) is
	begin
		for i in 1 to cnt loop
			rot <= "10"; wait for pause; rot<= "11"; wait for pause;
			rot <= "01"; wait for pause; rot<= "00"; wait for pause;
		end loop;
	end;

	-- rotate the knob to the left cnt times
	procedure lrot(cnt: in integer) is
	begin
		for i in 1 to cnt loop
			rot <= "01"; wait for pause; rot<= "11"; wait for pause;
			rot <= "10"; wait for pause; rot<= "00"; wait for pause;
		end loop;
	end;

	-- press down on the knob cnt times
	procedure bump(cnt: in integer) is
	begin
		for i in 1 to cnt loop
			press<='1'; wait for pause; press<='0'; wait for pause;
		end loop;
	end;

	-- push the reset button
	procedure reset is
	begin
		btn(0) <= '1'; wait for pause; btn(0) <= '0'; wait for pause;
	end;
	
	-- Start a round of tests using a specified repeat count
	procedure restart(count: in nibble) is begin
		bump(2);
		if	count > repCount then rrot(int(count - repCount));
		elsif count < repCount then lrot(int(repCount - count));
		end if;
		repCount <= count;
		bump(2);
		btn(1) <= '1'; wait for pause; btn(1) <= '0'; wait for pause;
	end;
	
	-- Input one symbol to the circuit, where x"0" corresponds to 'a',
	-- x"1 to b and so forth
	procedure nextSym(sym: in nibble) is begin
		if	sym > inSym then rrot(int(sym - inSym));
		elsif sym < inSym then lrot(int(inSym - sym));
		end if;
		inSym <= sym;
		btn(2) <= '1'; wait for pause; btn(2) <= '0'; wait for pause;
	end;
	
	-- Input a string of up to 9 hex digits. The input vector holds
	-- exactly 10 and  f is interpreted as a termination character.
	-- So for example, use nextSymVec(x"0132ffffff") to input the
	-- symbols x0, 1, 3 and 2.
	procedure nextSymVec(ss: in std_logic_vector(0 to 39)) is begin
		for i in 0 to 10 loop
			if ss(4*i to 4*i+3) = x"f" then exit; end if;
			nextSym(ss(4*i to 4*i+3));
		end loop;
	end;

	begin		
		wait for 100 ns;	
	
		reset; -- reset circuit using reset procedure above
		
		-- start with a set of tests using a repeat count of 3	  
		-- first test all the cases where the input matches the pattern
		-- be sure to to use all the state-machine transitions that
		-- lead to successful matche
		
		restart(x"3");
		nextSymVec(x"01113fffff");--  a->bbb->d
		nextSymVec(x"023fffffff");--  a->c->d
		nextSymVec(x"0023213fff");--  some other test that also pass with aa
	
		-- next add cases that fail after matching one or more initial
		-- 'a' characters
	
		
		nextSymVec(x"03ffffffff");
		nextSymVec(x"07ffffffff");--fail after matching a.

		
		-- now cases that fail after matching ab
	
		nextSymVec(x"01110fffff");  --abbba
		nextSymVec(x"01111fffff");	 --abbbb
		nextSymVec(x"01112fffff");  --abbbc
		nextSymVec(x"01115fffff");  --abbbf
		nextSymVec(x"0110ffffff"); --fail after matching ab.
	
		
		-- and finally, cases that fail after matching ac
		nextSymVec(x"020fffffff"); --aca
		nextSymVec(x"021fffffff"); --acb
		nextSymVec(x"022fffffff"); --acc

	
	
		-- now, a few more tests using a repeat count of 1
	restart(x"1");
		nextSymVec(x"013fffffff");--abd(p)
		nextSymVec(x"003fffffff");--aad(f)
		nextSymVec(x"0113ffffff");--abbd(f)
		nextSymVec(x"023fffffff");--acd(p)
		nextSymVec(x"0223ffffff");--accd(f)
		nextSymVec(x"231fffffff");--cdb(f)

	
	      wait for 50 ns;--wait for the graph!	

	
		assert (false) report "normal termination" severity failure;
	end process;

END;
