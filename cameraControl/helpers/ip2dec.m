%% Convert ip adress in hexadecimal format
function decIP = ip2dec(ipAddress)
    ipParts = str2double(split(ipAddress, '.'));
    decIP = uint32(ipParts(1) * 2^24 + ipParts(2) * 2^16 + ipParts(3) * 2^8 + ipParts(4));
end
