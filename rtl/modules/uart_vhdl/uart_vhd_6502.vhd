library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity UART_VHD_6502 is
    port (
        CLK       : in  std_logic;
        RST       : in  std_logic;
        UART_TXD  : out std_logic;
        UART_RXD  : in  std_logic;
        DIN       : in  std_logic_vector(7 downto 0);
        DIN_VLD   : in  std_logic;
        DIN_RDY   : out std_logic;
        DOUT      : out std_logic_vector(7 downto 0);
        DOUT_VLD  : out std_logic
    );
end entity;

architecture RTL of UART_VHD_6502 is 

begin
    UART_6502_inst : entity work.UART
    generic map (
        CLK_FREQ => 48000000,
        BAUD_RATE => 230400
    )
    port map (
        CLK      => CLK,
        RST      => RST,
        UART_TXD => UART_TXD,
        UART_RXD => UART_RXD,
        DIN      => DIN,
        DIN_VLD  => DIN_VLD,
        DIN_RDY  => DIN_RDY,
        DOUT     => DOUT,
        DOUT_VLD => DOUT_VLD
    );
end architecture;