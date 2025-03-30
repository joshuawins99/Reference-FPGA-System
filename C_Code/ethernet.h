unsigned char EthTransfer(unsigned, char, char);
void EthSendUDP(unsigned char, char *);
void EthRecvUDP(unsigned char);
void EthInitialize(unsigned char);
void OpenEthUDPSocket(unsigned char, unsigned, unsigned, unsigned char[4]);
void CloseEthUDPSocket(unsigned char);
