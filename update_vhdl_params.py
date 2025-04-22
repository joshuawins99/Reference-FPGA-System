import re
import sys

top_module_filename = sys.argv[1]

top_module_path = 'rtl/' + top_module_filename
vhdl_cpu_uart_path = 'rtl/modules/uart_vhdl/uart_vhd_cpu.vhd'
search_string_clk_speed = 'FPGAClkSpeed'
search_string_cpu_uart_speed = 'BaudRateCPU'

FPGAClkSpeedLine = ""
FPGAClkSpeedNum = 0

UARTSpeedcpuLine = ""
UARTSpeedcpuNum = 0

# Open the file and iterate through each line
with open(top_module_path, 'r') as file:
    for line in file:
        if search_string_clk_speed in line:
            FPGAClkSpeedLine = line.strip()
            file.close()
            break

# Use regex to find the number
match = re.search(r'\b\d+\b', FPGAClkSpeedLine)
if match:
    FPGAClkSpeedNum = match.group()



# Open the file and iterate through each line
with open(top_module_path, 'r') as file:
    for line in file:
        if search_string_cpu_uart_speed in line:
            UARTSpeedcpuLine = line.strip()
            file.close()
            break

# Use regex to find the number
match = re.search(r'\b\d+\b', UARTSpeedcpuLine)
if match:
    UARTSpeedcpuNum = match.group()



with open(vhdl_cpu_uart_path, 'r') as file:
    content = file.read()

# Use regex to replace the number
pattern = r'CLK_FREQ\s*=>\s*\d+'
new_content = re.sub(pattern, f'CLK_FREQ => {FPGAClkSpeedNum}', content)

# Write the modified content back to the file
with open(vhdl_cpu_uart_path, 'w') as file:
    file.write(new_content)


with open(vhdl_cpu_uart_path, 'r') as file:
    content = file.read()

# Use regex to replace the number
pattern = r'BAUD_RATE\s*=>\s*\d+'
new_content = re.sub(pattern, f'BAUD_RATE => {UARTSpeedcpuNum}', content)

# Write the modified content back to the file
with open(vhdl_cpu_uart_path, 'w') as file:
    file.write(new_content)