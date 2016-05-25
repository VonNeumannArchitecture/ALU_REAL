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
    constant CMD_NOP : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    constant CMD_WRITE : STD_LOGIC_VECTOR(3 downto 0) := "0011";
    constant CMD_LOAD : STD_LOGIC_VECTOR(3 downto 0) := "0001";
    constant CMD_SHIFT_R : STD_LOGIC_VECTOR(3 downto 0) := "1001";
    constant CMD_SHIFT_L : STD_LOGIC_VECTOR(3 downto 0) := "1010";
    constant CMD_ADD : STD_LOGIC_VECTOR(3 downto 0) := "1011";
    constant CMD_SUB : STD_LOGIC_VECTOR(3 downto 0) := "1100";
    constant CMD_AND : STD_LOGIC_VECTOR(3 downto 0) := "0101";
    constant CMD_OR : STD_LOGIC_VECTOR(3 downto 0) := "0110";
    constant CMD_INV : STD_LOGIC_VECTOR(3 downto 0) := "0111";
       
    signal akku : STD_LOGIC_VECTOR (datawidth downto 0) := (others => '0'); 
    signal init : STD_LOGIC := '1';
    
    alias CARRY_F : STD_LOGIC is status(0);
    alias ZERO_F : STD_LOGIC is status(1);
    alias NEGATIVE_F : STD_LOGIC is status(2);
    alias OVERFLOW_F : STD_LOGIC is status(3);  
    
begin

alu_proc : process(clk)   
    variable operand : STD_LOGIC_VECTOR(datawidth downto 0) := (others => '0');
    variable result : STD_LOGIC_VECTOR(datawidth downto 0) := (others => '0');
    variable updateStatus : STD_LOGIC_VECTOR(3 downto 0) := "0110";
    
    alias UPDATE_CARRY : STD_LOGIC is updateStatus(0);
    alias UPDATE_ZERO : STD_LOGIC is updateStatus(1);
    alias UPDATE_NEGATIVE : STD_LOGIC is updateStatus(2);
    alias UPDATE_OVERFLOW : STD_LOGIC is updateStatus(3);
begin
    if init = '1' then
        init <= '0';
        status <= "0000";
    end if;

    if rising_edge(clk) then
        data <= (data'range => 'Z');
        updateStatus := "0110";
        result := (result'range => '0');
        operand := (operand'range => '0');
        
        case command is
            when CMD_NOP =>
                UPDATE_ZERO := '0';
                UPDATE_NEGATIVE := '0';
                
            when CMD_WRITE =>                   
                data <= akku(datawidth-1 downto 0);
                UPDATE_ZERO := '0';
                UPDATE_NEGATIVE := '0';
                
            when CMD_LOAD =>
                result := '0' & data;
                akku <= result;
                UPDATE_CARRY := '1';
                
            when CMD_SHIFT_R =>
                result := akku(0) & '0' & akku(datawidth-1 downto 1);
                akku <= result;
                UPDATE_CARRY := '1';
                
            when CMD_SHIFT_L =>
                result := akku(datawidth-1 downto 0) & '0';
                akku <= result;
                UPDATE_CARRY := '1';
                
            when CMD_ADD =>
                operand := '0' & data;
                result := akku + operand;
                akku <= result;
                UPDATE_CARRY := '1';
                UPDATE_OVERFLOW := '1';
                
            when CMD_SUB =>
                operand := '0' & (not(data) + 1);
                result := akku + operand;
                akku <= result;
                UPDATE_CARRY := '1';
                UPDATE_OVERFLOW := '1';
                
            when CMD_AND =>
                operand := '0' & data;
                result := akku AND operand;
                akku <= result;
                
            when CMD_OR =>
                operand := '0' & data;
                result := akku OR operand;
                akku <= result;
                
            when CMD_INV =>
                result := '0' & not akku(datawidth-1 downto 0);     
                akku <= result;
                
            when others =>
                assert false report "No valid Command" severity error;
                
        end case; 
        
        -- Status flags
        -- http://teaching.idallen.com/dat2343/10f/notes/040_overflow.txt
        
        -- Carry
        if (UPDATE_CARRY = '1') then
            Carry_F <= result(datawidth);                  
        end if;
        
        -- Zero  
        if (UPDATE_ZERO = '1') then                          
            if (result(datawidth-1 downto 0) = (result'range => '0')) then
                Zero_F <= '1';
            else
                Zero_F <= '0';
            end if;
        end if;
        
        -- Negative
        if(UPDATE_NEGATIVE = '1') then            
            Negative_F <= result(datawidth-1);
        end if;
        
        -- Overflow
        if (UPDATE_OVERFLOW = '1') then
            if (akku(datawidth-1) = '0' AND operand(datawidth-1) = '0' AND result(datawidth-1) = '1') then
                -- Adding two positives should be positive
                Overflow_F <= '1';
            elsif (akku(datawidth-1) = '1' AND operand(datawidth-1) = '1' AND result(datawidth-1) = '0') then
                -- Adding two negatives should be negative
                Overflow_F <= '1';
            else
                Overflow_F <= '0';
            end if;
        end if;       
             
    end if;   
end process;

end Behavioral;
