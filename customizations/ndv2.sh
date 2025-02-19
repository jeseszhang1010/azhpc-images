#!/bin/bash
set -ex

# Place NDv2 topology file under /opt/microsoft/ndv2
mkdir -p /opt/microsoft/ndv2
bash -c "cat > /opt/microsoft/ndv2/topo.xml" <<'EOF'
<system version="1">
  <cpu numaid="0" affinity="0000ffff,0000ffff" arch="x86_64" vendor="GenuineIntel" familyid="6" modelid="85">
    <pci busid="0001:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0002:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0003:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0004:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0101:00:00.0" class="0x020700" link_speed="16 GT/s" link_width="16"/>
  </cpu>
  <cpu numaid="1" affinity="0000ffff,0000ffff" arch="x86_64" vendor="GenuineIntel" familyid="6" modelid="85">
    <pci busid="0005:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0006:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0007:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
    <pci busid="0008:00:00.0" class="0x030200" link_speed="16 GT/s" link_width="16"/>
  </cpu>
</system>
EOF

## Set NCCL configuration file for NDv2
bash -c "cat > /etc/nccl.conf" <<'EOF'
NCCL_TOPO_FILE=/opt/microsoft/ndv2/topo.xml
EOF
