library IEEE;
use IEEE.std_logic_1164.all;
use work.MIPS_package.all;


entity ControlPath is
    port (
        clock           : in std_logic;
        reset           : in std_logic;
        ctrl            : out control;
        flg             : in flags
    );
end ControlPath;

architecture arch of ControlPath is
    type state is (s0, s1, s2, s3, s4, s5);
    signal cs : state;
    -- Alias to identify the instructions based on the 'opcode' and 'funct' fields
    alias  opcode: std_logic_vector(5 downto 0) is flg.instruction(31 downto 26);
    alias  funct: std_logic_vector(5 downto 0) is flg.instruction(5 downto 0);

    -- Retrieves the rs field from the instruction
    alias rs: std_logic_vector(4 downto 0) is flg.instruction(25 downto 21);
    -- Retrieves the rt field from the instruction
    alias rt: std_logic_vector(4 downto 0) is flg.instruction(20 downto 16);
    -- Retrieves the rd field from the instruction
    alias rd: std_logic_vector(4 downto 0) is flg.instruction(15 downto 11);

    signal decodedInstruction: operation_type;

begin

    ctrl.ALUop <= decodedInstruction;     -- Used to set the ALU operation

    -- Instruction decode
    decodedInstruction <=   ADD     when opcode = "000000" and funct = "100000" else
                            XXOR    when opcode = "000000" and funct = "100110" else
                            --check this later
                            SLT     when opcode = "000000" and funct = "101010" else
                            SLTU    when opcode = "000000" and funct = "101011" else
                                --check this later
                            SW      when opcode = "101011" else
                            LW      when opcode = "100011" else
                            ADDI    when opcode = "001000" else
                            ORI     when opcode = "001101" else
                            BEQ     when opcode = "000100" else
                            BNE     when opcode = "000101" else
                            LUI     when opcode = "001111" and rs = "00000" else
                            ADD;    --default operation is add

    state_logic : process(flg.instruction, clock, reset)
    begin
        if reset = '1' then
            cs <= s0;
        elsif rising_edge(clock) then
            case cs is
                when s0 =>
                    cs <= s1;
                when s1 =>
                    cs <= s2;
                when s2 =>
                    if opcode = "000000" then       --R type
                        cs <= s3;
                    else
                    end if;
                when s3 =>
                    cs <= s4;
                when s4 =>
                    cs <= s0;
		when s5 =>
		    cs <= s0;
            end case;
        end if;
    end process;

    --all command signals are only state based (moore FSM)
    --currently only has type R conditions!!!!!
    ctrl.PCSource <= '1' when cs = s0 else '0';
    ctrl.WrPC <= '1' when cs = s0 else '0';
    ctrl.PCconditional <= '0'; --todo
    ctrl.WrRfile <= '1' when cs = s4 else '0';
    ctrl.RegDst <= '1' when cs = s4 else '0';
    ctrl.WrIR <= '1' when cs = s0 else '0';
    ctrl.MemToReg <= '0'; --todo
    ctrl.WrMem <= '0'; --TODO
    ctrl.WrMDR <= '0'; --TODO
    ctrl.IorD <= '0'; --TODO
    ctrl.WrA <= '1' when cs = s1 else '0';
    ctrl.WrB <= '1' when cs = s1 else '0';
    ctrl.ALUSrcB <= "11" when cs = s2 else
                    --"10" when  else
                    "01" when cs = s0 else
                    "00";
    ctrl.ALUSrcA <= '0' when cs = s0 or cs = s1 else '1';   -- 0 selects the pc and we only use it in the ALU in the fetch phase
    ctrl.WrALU  <= '1' when cs = s1 or cs = s3 else '0';

end architecture;