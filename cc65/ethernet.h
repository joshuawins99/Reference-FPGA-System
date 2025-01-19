const unsigned char gw_ip[4] = {192,168,1,1};
const unsigned char subnet_mask[4] = {255,255,255,0};
const unsigned char mac_address[6] = {0x00, 0x08, 0xDC, 0x01, 0x02, 0x03};
const unsigned char ip_address[4] = {192,168,1,254};
unsigned char ethinit[8] = {0,0,0,0,0,0,0,0};

enum w5500commonregs {
    mode_reg_e = 0,
    gateway_ip_e,
    subnet_mask_e,
    mac_address_e,
    ip_address_e,
    chip_ident_e,
    phy_cfg_e
};

const unsigned w5500common[] = {
    0x0000, //Mode Register
    0x0001, //Gateway IP Address
    0x0005, //Subnet Mask
    0x0009, //MAC Adddress
    0x000F, //IP Address
    0x0039, //Chip Identifier
    0x002E, //PHY Configuration
};

enum w5500socketregs {
    socket_mode_e = 0,
    socket_command_e,
    socket_interrupt_e,
    socket_status_e,
    socket_source_port_e,
    socket_dest_hw_address_e,
    socket_dest_ip_address_e,
    socket_dest_port_e,
    socket_tx_read_ptr_e,
    socket_tx_write_ptr_e,
    socket_rx_recv_size_e,
    socket_rx_read_ptr_e,
    socket_rx_write_ptr_e
};

const unsigned w5500socket[] = {
    0x0000, //Socket Mode
    0x0001, //Socket Command
    0x0002, //Socket Interrupt
    0x0003, //Socket Status
    0x0004, //Socket Source Port
    0x0006, //Socket Destination Hardware Address
    0x000C, //Socket Destination IP Address
    0x0010, //Socket Destination Port
    0x0022, //Socket TX Read Pointer
    0x0024, //Socket TX Write Pointer
    0x0026, //Socket RX Received Size
    0x0028, //Socket RX Read Pointer
    0x002A  //Socket RX Write Pointer
};

enum w5500blocksel {
    common_e = 0,
    socket0_reg_e,
    socket0_tx_buffer_e,
    socket0_rx_buffer_e,
    socket1_reg_e,
    socket1_tx_buffer_e,
    socket1_rx_buffer_e
};

const unsigned char w5500read[] = {
    0b00000001, //Common Register Read
    0b00001001, //Socket 0 Register Read
    0b00010001, //Socket 0 TX Buffer
    0b00011001, //Socket 0 RX Buffer
    0b00101001, //Socket 1 Register Read
    0b00110001, //Socket 1 TX Buffer
    0b00111001  //Socket 1 RX Buffer
};

const unsigned char w5500write[] = {
    0b00000101, //Common Register Write
    0b00001101, //Socket 0 Reg Write
    0b00010101, //Socket 0 TX Buffer Write
    0b00011101, //Socket 0 RX Buffer Write
    0b00101101, //Socket 1 Reg Write
    0b00110101, //Socket 1 TX Buffer Write
    0b00111101  //Socket 1 RX Buffer Write
};

unsigned char EthTransfer(unsigned, char, char);
void EthSendUDP(unsigned char, char[]);
void EthRecvUDP(unsigned char);
void EthInitialize(unsigned char);
void OpenEthUDPSocket(unsigned char, unsigned, unsigned, unsigned char[4]);
void CloseEthUDPSocket(unsigned char);
