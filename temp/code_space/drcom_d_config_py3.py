# -*- coding: utf-8 -*-
"""
Created on Wed Dec 03 23:45:49 2014
Last Modified: 2016/10/19 12:13
@author: latyas
Converted to Python3 on 2025/04/16
"""

from binascii import hexlify
import re

def hexed(s):
    ret = ''
    for i in s:
        ret += '\\x' + hex(i)[2:].rjust(2, '0')
    return ret

filename = 'dr.pcapng'
with open(filename, 'rb') as f:
    text = f.read()
offset = re.search(b'\xF0\x00\xF0\x00[\x00-\xFF]{4}[\x03\x07]\x01', text).start() + 8
#print(hexlify(text[offset:offset+330]))
#print(hexlify(text[offset:offset+338]))
# print(text[offset+334:offset+338].hex())
if re.match(b'\x00\x00[\x00-\xFF]{2}', text[offset+334:offset+338]):
    ror_version = True
else:
    ror_version = False
# print(ror_version)
username_len = text[offset+3] - 20
username = text[offset+20:offset+20+username_len].decode('utf-8', errors='ignore')
print('server = \'%s\'' % '.'.join([str(i) for i in text[offset-12:offset-8]]))
print('username=\'%s\'' % username)
print('password=\'\'')
print('CONTROLCHECKSTATUS = \'%s\'' % hexed(bytes([text[offset+56]])))
print('ADAPTERNUM = \'%s\'' % hexed(bytes([text[offset+57]])))
print('host_ip = \'%s\'' % '.'.join([str(i) for i in text[offset+81:offset+85]]))
print('IPDOG = \'%s\'' % hexed(bytes([text[offset+105]])))
print('host_name = \'%s\'' % 'GILIGILIEYE')
print('PRIMARY_DNS = \'%s\'' % '.'.join([str(i) for i in text[offset+142:offset+146]]))
print('dhcp_server = \'%s\'' % '.'.join([str(i) for i in text[offset+146:offset+150]]))
print('AUTH_VERSION = \'%s\'' % hexed(text[offset+310:offset+312]))
if ror_version:
    print('mac = 0x%s' % hexlify(text[offset+328:offset+334]).decode('utf-8'))
else:
    print('mac = 0x%s' % hexlify(text[offset+320:offset+326]).decode('utf-8'))
print('host_os = \'%s\'' % 'NOTE7')

# 添加错误处理，防止索引错误
keep_alive_matches = [i for i in re.findall(b'\xf0\x00\xf0\x00....\x07.\x5c\x28\x00\x0b\x01(..)', text) if i != b'\x0f\x27']
if keep_alive_matches:
    KEEP_ALIVE_VERSION = keep_alive_matches[0]
    print('KEEP_ALIVE_VERSION = \'%s\'' % hexed(KEEP_ALIVE_VERSION))
else:
    # 提供一个默认值或仅报告未找到
    print('KEEP_ALIVE_VERSION 未找到，使用默认值')
    print('KEEP_ALIVE_VERSION = \'\\x00\\x00\'')  # 使用默认值

print('ror_version = %s ' % ror_version)