#include "ethernet.h"
#include "io.h"

const unsigned char gw_ip[4] = {10,194,1,1};
const unsigned char subnet_mask[4] = {255,255,255,0};
const unsigned char mac_address[6] = {0x00, 0x08, 0xDC, 0x01, 0x02, 0x03};
const unsigned char ip_address[4] = {10,194,1,254};
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
    socket_tx_buffer_size_e,
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
    0x001F, //Socket Transmit Buffer Size
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

unsigned char EthTransfer(unsigned addr, char control, char tx_data) {
    unsigned char data;
    
    WriteIO(Ethernet_SPI_BaseAddress, (addr >> 8));
    WriteIO(Ethernet_SPI_BaseAddress, (addr & 0x00FF));
    WriteIO(Ethernet_SPI_BaseAddress, control);
    WriteIO(Ethernet_SPI_BaseAddress, tx_data);
    WriteIO(Ethernet_SPI_BaseAddress+(2*ADDR_WORD), 1); // Start Transaction in SPI Module

    // Wait for transaction to complete
    while (ReadIO(Ethernet_SPI_BaseAddress+(3*ADDR_WORD)) == 1);
    #if !defined(LLVM) && !defined(RV32)
        data = ReadIO(Ethernet_SPI_BaseAddress+1);
        __asm__ ("nop");
        data = ReadIO(Ethernet_SPI_BaseAddress+1);
        __asm__ ("nop");
        data = ReadIO(Ethernet_SPI_BaseAddress+1);
        __asm__ ("nop");
        data = ReadIO(Ethernet_SPI_BaseAddress+1);
    #else
        data = ReadIO(Ethernet_SPI_BaseAddress+(1*ADDR_WORD));
        data = ReadIO(Ethernet_SPI_BaseAddress+(1*ADDR_WORD));
        data = ReadIO(Ethernet_SPI_BaseAddress+(1*ADDR_WORD));
        data = ReadIO(Ethernet_SPI_BaseAddress+(1*ADDR_WORD));
    #endif

    return data;
}

void EthSendUDP (unsigned char socketnum, char *data) {
    unsigned char i;
    unsigned char tx_pointer[2];
    unsigned tx_pointer_16;
    unsigned char strdatalen = strlen(data);
    unsigned char rwptr = (3*socketnum)+1;

    tx_pointer[0] = EthTransfer(w5500socket[socket_tx_read_ptr_e], w5500read[rwptr], 0); //Read TX Pointer
    tx_pointer[1] = EthTransfer(w5500socket[socket_tx_read_ptr_e]+1, w5500read[rwptr], 0); //Read TX Pointer
    tx_pointer_16 = (tx_pointer[0] << 8) | tx_pointer[1];
    for (i=0; i < strdatalen; ++i) {
        EthTransfer(tx_pointer_16+i, w5500write[rwptr+1], data[i]);
    }
    tx_pointer_16 += strdatalen;
    EthTransfer(w5500socket[socket_tx_write_ptr_e], w5500write[rwptr], (tx_pointer_16 >> 8));
    EthTransfer(w5500socket[socket_tx_write_ptr_e]+1, w5500write[rwptr], (tx_pointer_16 & 0x00FF));
    EthTransfer(w5500socket[socket_command_e], w5500write[rwptr] , 0x20); //Send UDP Data
}

void EthRecvUDP(unsigned char socketnum) {
    unsigned char rx_recv_size[2];
    unsigned rx_recv_size_16;
    unsigned rx_data_size_16;
    unsigned char rx_pointer[2];
    unsigned rx_pointer_16;
    unsigned char received_data_header[8];
    unsigned char i;
    char received_packet_data[30];
    char *commandOutput;
    unsigned update_rx_read_ptr_val;
    unsigned char rwptr = (3*socketnum)+1;

    if (ethinit[socketnum] != 1) return;
    rx_recv_size[0] = EthTransfer(w5500socket[socket_rx_recv_size_e], w5500read[rwptr], 0);
    rx_recv_size[1] = EthTransfer(w5500socket[socket_rx_recv_size_e]+1, w5500read[rwptr], 0);
    rx_recv_size_16 = (rx_recv_size[0] << 8) | rx_recv_size[1];
    if (rx_recv_size_16 == 0x0000) return;
    rx_pointer[0] = EthTransfer(w5500socket[socket_rx_read_ptr_e], w5500read[rwptr], 0);
    rx_pointer[1] = EthTransfer(w5500socket[socket_rx_read_ptr_e]+1, w5500read[rwptr], 0);
    rx_pointer_16 = (rx_pointer[0] << 8) | rx_pointer[1];
    for (i = 0; i < 8; ++i) {
        received_data_header[i] = EthTransfer(rx_pointer_16+i, w5500read[rwptr+2], 0);
    }
    rx_data_size_16 = (received_data_header[6] << 8) | received_data_header[7];
    rx_pointer_16 += 8;
    for (i = 0; i < rx_data_size_16; ++i) {
        received_packet_data[i] = EthTransfer(rx_pointer_16+i, w5500read[rwptr+2], 0);
    }
    update_rx_read_ptr_val = rx_pointer_16 + rx_data_size_16;
    EthTransfer(w5500socket[socket_rx_read_ptr_e], w5500write[rwptr], (update_rx_read_ptr_val >> 8));
    EthTransfer(w5500socket[socket_rx_read_ptr_e]+1, w5500write[rwptr], (update_rx_read_ptr_val & 0x00FF));
    EthTransfer(w5500socket[socket_command_e], w5500write[rwptr], 0x40); // Send RECV Command

    commandOutput = executeCommandsSerial(&received_packet_data[0]);
    memset(&received_packet_data[0], 0, rx_data_size_16);
    if (commandOutput != NULL) {
        EthSendUDP(0, &commandOutput[0]);
    }
}

void EthInitialize (unsigned char debug) {
    unsigned char data;
    unsigned char i;

    for (i = 0; i < sizeof(ethinit); ++i) {
        ethinit[i] = 0;
    }
    EthTransfer(w5500common[mode_reg_e], w5500write[common_e], 128); //Reset Ethernet Chip
    data = EthTransfer(w5500common[mode_reg_e], w5500read[common_e], 0);
    while (1) {
        if ((data & 128) == 0) {
            break;
        } else {
            data = EthTransfer(w5500common[mode_reg_e], w5500read[common_e], 0);
        }
    }
    if (debug == 1) {
        Sleep(30000); //Sleep 3 Seconds to give time for determining the link status
        data = EthTransfer(w5500common[chip_ident_e], w5500read[common_e], 0);
        if (data == 4) {
            Print(1,"Wiznet W5500 Detected!");
            data = EthTransfer(w5500common[phy_cfg_e], w5500read[common_e], 0);
            if ((data & 1) == 1) {
                Print(1,"Link Up!");
            } else {
                Print(1,"Link Down!");
            }
        } else {
            Print(1,"Ethernet Chip Not Detected!");
        }
    }
    for(i = 0; i < 4; ++i) { //Send Gateway IP Address
        EthTransfer(w5500common[gateway_ip_e]+i, w5500write[common_e], gw_ip[i]);
    }
    for(i = 0; i < 4; ++i) { //Send Subnet Mask
        EthTransfer(w5500common[subnet_mask_e]+i, w5500write[common_e], subnet_mask[i]);
    }
    for(i = 0; i < 6; ++i) { //Send MAC Address
        EthTransfer(w5500common[mac_address_e]+i, w5500write[common_e], mac_address[i]);
    }
    for(i = 0; i < 4; ++i) { //Send IP Address
        EthTransfer(w5500common[ip_address_e]+i, w5500write[common_e], ip_address[i]);
    }
}

void OpenEthUDPSocket (unsigned char socketnum, unsigned source_port, unsigned destination_port, unsigned char dest_ip_addr[4]) {
    unsigned char i;
    unsigned char rwptr = (3*socketnum)+1;
    
    if (ethinit[socketnum] == 0) {
        EthTransfer(w5500socket[socket_mode_e], w5500write[rwptr], 0b00000010); //Configure UDP Socket
        EthTransfer(w5500socket[socket_source_port_e], w5500write[rwptr], (source_port >> 8)); //Configure Source Port
        EthTransfer(w5500socket[socket_source_port_e]+1, w5500write[rwptr], (source_port & 0x00FF)); //Configure Source Port
        EthTransfer(w5500socket[socket_dest_port_e], w5500write[rwptr], (destination_port >> 8)); //Configure Destination Port
        EthTransfer(w5500socket[socket_dest_port_e]+1, w5500write[rwptr], (destination_port & 0x00FF)); //Configure Destination Port
        for(i = 0; i < 4; ++i) {
            EthTransfer(w5500socket[socket_dest_ip_address_e]+i, w5500write[rwptr] , dest_ip_addr[i]); //Configure Destination IP Address
        }
        //EthTransfer(w5500socket[socket_tx_buffer_size_e], w5500write[rwptr], 16); //Set TX Buffer size to 16KB
        EthTransfer(w5500socket[socket_command_e], w5500write[rwptr], 1); //Open UDP Socket
        ethinit[socketnum] = 1;
    }
}

void CloseEthUDPSocket (unsigned char socketnum) {
    EthTransfer(w5500socket[socket_command_e], w5500write[(3*socketnum)+1], 0x10); //Close UDP Socket
    ethinit[socketnum] = 0;
}