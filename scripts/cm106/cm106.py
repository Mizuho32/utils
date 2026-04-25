import hid
 
h = hid.device()
# 0d8c:0102
h.open(0x0D8C,0x0102)
send_data = [0x00, 0x30, 0x00, 0x00, 0x01]
 
h.write(send_data)
get_data = h.read(32)
print(get_data)
