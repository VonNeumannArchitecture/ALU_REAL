----------------------------------------------------------------------------------
-- Company: HS Mannheim
-- Engineer: Jürgen Altszeimer
-- 
-- Create Date: 27.04.2016 11:37:19
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: Von Neumann Prozessor
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ALU is
    generic (
        datawidth : integer := 8
    );
    Port ( 
        clk : in STD_LOGIC;
        data : inout STD_LOGIC_VECTOR (datawidth-1 downto 0);
        status : out STD_LOGIC_VECTOR (3 downto 0);
        command : in STD_LOGIC_VECTOR (3 downto 0)
     );        
end ALU;

architecture Behavioral of ALU is
    constant C_NOP : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    constant C_WRITE : STD_LOGIC_VECTOR(3 downto 0) := "0011";
    constant C_LOAD : STD_LOGIC_VECTOR(3 downto 0) := "0001";
    constant C_SHIFT_R : STD_LOGIC_VECTOR(3 downto 0) := "1001";
    constant C_SHIFT_L : STD_LOGIC_VECTOR(3 downto 0) := "1010";
    constant C_ADD : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    constant C_SUB : STD_LOGIC_VECTOR(3 downto 0) := "1100";
    constant C_AND : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    constant C_OR : STD_LOGIC_VECTOR(3 downto 0) := "0110";
    constant C_INV : STD_LOGIC_VECTOR(3 downto 0) := "0111";
       
    signal akku : STD_LOGIC_VECTOR (datawidth-1 downto 0) := (others => '0'); 
    
    type command_state_name is (CMD_NOP, CMD_WRITE, CMD_LOAD, CMD_SHIFT_R, CMD_SHIFT_L, CMD_ADD, CMD_SUB, CMD_AND, CMD_OR, CMD_INV);
    signal command_state : command_state_name;
        
    signal carry : STD_LOGIC := '0';
    signal zero : STD_LOGIC := '0';
    signal negative : STD_LOGIC := '0';
    signal overflow : STD_LOGIC := '0';
    
begin
    status(0) <= carry;
    status(1) <= zero;
    status(2) <= negative;
    status(3) <= overflow;
    
    with command select
        command_state <= CMD_WRITE when C_WRITE,
                         CMD_LOAD when C_LOAD,
                         CMD_SHIFT_L when C_SHIFT_L,
                         CMD_SHIFT_R when C_SHIFT_R,
                         CMD_ADD when C_ADD,
                         CMD_SUB when C_SUB,
                         CMD_AND when C_AND,
                         CMD_OR when C_OR,
                         CMD_INV when C_INV,
                         CMD_NOP when others;

alu_proc : process(clk)   
    variable operand : STD_LOGIC_VECTOR(datawidth-1 downto 0) := (others => '0');
    variable result : STD_LOGIC_VECTOR(datawidth downto 0) := (others => '0');
    variable updateStatus : STD_LOGIC_VECTOR(3 downto 0) := "0110";
    
    alias UPDATE_CARRY : STD_LOGIC is updateStatus(0);
    alias UPDATE_ZERO : STD_LOGIC is updateStatus(1);
    alias UPDATE_NEGATIVE : STD_LOGIC is updateStatus(2);
    alias UPDATE_OVERFLOW : STD_LOGIC is updateStatus(3);
begin   
    if rising_edge(clk) then
        data <= (data'range => 'Z');
        updateStatus := "0110";
        result := (result'range => '0');
        operand := (operand'range => '0');
        
        case command is
            when C_NOP =>
                UPDATE_ZERO := '0';
                UPDATE_NEGATIVE := '0';
                
            when C_WRITE =>                
                data <= akku;
                UPDATE_ZERO := '0';
                UPDATE_NEGATIVE := '0';
                
            when C_LOAD =>
                result := '0' & data;
                akku <= result(datawidth-1 downto 0);
                UPDATE_CARRY := '1';
                
            when C_SHIFT_R =>
                result := akku(0) & '0' & akku(datawidth-1 downto 1);
                akku <= result(datawidth-1 downto 0);
                UPDATE_CARRY := '1';
                
            when C_SHIFT_L =>
                result := akku & '0';
                akku <= result(datawidth-1 downto 0);
                UPDATE_CARRY := '1';
                
            when C_ADD =>
                operand := data;
                result := ('0' & akku) + ('0' & operand);
                akku <= result(datawidth-1 downto 0);
                UPDATE_CARRY := '1';
                UPDATE_OVERFLOW := '1';
                
            when C_SUB =>
                operand := (not(data) + 1);
                result := ('0' & akku) + ('0' & operand);
                akku <= result(datawidth-1 downto 0);
                UPDATE_CARRY := '1';
                UPDATE_OVERFLOW := '1';
                
            when C_AND =>
                operand := data;
                result := '0' & (akku AND operand);
                akku <= result(datawidth-1 downto 0);
                
            when C_OR =>
                operand := data;
                result := '0' & (akku OR operand);
                akku <= result(datawidth-1 downto 0);
                
            when C_INV =>
                result := '0' & (not akku);     
                akku <= result(datawidth-1 downto 0);
                
            when others =>
                assert false report "No valid Command" severity error;
                
        end case; 
        
        -- Status flags
        -- http://teaching.idallen.com/dat2343/10f/notes/040_overflow.txt
        
        -- Carry
        if (UPDATE_CARRY = '1') then
            carry <= result(datawidth);                  
        end if;
        
        -- Zero  
        if (UPDATE_ZERO = '1') then                          
            if (result(datawidth-1 downto 0) = (result'range => '0')) then
                zero <= '1';
            else
                zero <= '0';
            end if;
        end if;
        
        -- Negative
        if(UPDATE_NEGATIVE = '1') then            
            negative <= result(datawidth-1);
        end if;
        
        -- Overflow
        if (UPDATE_OVERFLOW = '1') then
            if (akku(datawidth-2) = '0' AND operand(datawidth-2) = '0' AND result(datawidth-1) = '1') then
                -- Adding two positives should be positive
                overflow <= '1';
            elsif (akku(datawidth-2) = '1' AND operand(datawidth-2) = '1' AND result(datawidth-1) = '0') then
                -- Adding two negatives should be negative
                overflow <= '1';
            else
                overflow <= '0';
            end if;
        end if;       
             
    end if;   
end process;

end Behavioral;
