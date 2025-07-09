dev = open("/proc/net/dev", "r").readlines()
header_line = dev[1]
header_names = header_line[header_line.index("|")+1:].replace("|", " ").split()

values={}
for line in dev[2:]:
    intf = line[:line.index(":")].strip()
    values[intf] = [int(value) for value in line[line.index(":")+1:].split()]
    print intf,values[intf]
