#!/bin/bash

# 1. Quét lại ổ đĩa để nhận diện dung lượng mới từ VMware
echo 1 > /sys/class/block/sda/device/rescan

# Kiểm tra xem gói growpart đã có chưa
if ! command -v growpart &> /dev/null; then
    echo "Dang cai dat growpart..."
    if [ -f /etc/debian_version ]; then
        apt-get update && apt-get install -y cloud-guest-utils
    elif [ -f /etc/redhat-release ]; then
        yum install -y cloud-utils-growpart
    fi
fi

# Xác định ổ đĩa và phân vùng root
# Giả sử root nằm trên /dev/sda. Thay đổi nếu bạn dùng tên khác (ví dụ nvme0n1)
DISK="/dev/sda"
# Lấy số phân vùng cuối cùng hoặc phân vùng chứa LVM (thường là 2 hoặc 3)
# Cách đơn giản nhất là thử grow phân vùng thường chứa root
PARTITION_NUM=$(lsblk -no PKNAME,NAME,MOUNTPOINT | grep ' /$' | awk '{print $1}' | grep -o '[0-9]*$')

if [ -z "$PARTITION_NUM" ]; then
    # Trường hợp dùng LVM, lệnh trên có thể không ra số partition trực tiếp
    # Thường template Linux sẽ để LVM ở partition số 2 hoặc số 5 (logic)
    # Ở đây ta mặc định thử partition 2 (phổ biến nhất)
    PARTITION_NUM=2
fi

echo "Dang mo rong partition $PARTITION_NUM tren $DISK..."

# 2. Mở rộng Partition (Physical Partition)
growpart $DISK $PARTITION_NUM

# 3. Kiểm tra xem có dùng LVM không
if lvs &> /dev/null; then
    echo "Phat hien LVM. Dang xu ly LVM..."
    
    # Resize Physical Volume (PV)
    pvresize ${DISK}${PARTITION_NUM}
    
    # Tìm Logical Volume (LV) đang mount vào /
    LV_PATH=$(findmnt / -o SOURCE -n)
    
    # Mở rộng Logical Volume hết mức
    lvextend -l +100%FREE $LV_PATH
    
    # 4. Mở rộng Filesystem (LVM)
    FILE_SYSTEM_TYPE=$(findmnt / -o FSTYPE -n)
    if [ "$FILE_SYSTEM_TYPE" == "xfs" ]; then
        xfs_growfs /
    elif [ "$FILE_SYSTEM_TYPE" == "ext4" ]; then
        resize2fs $LV_PATH
    fi
else
    # 4. Mở rộng Filesystem (Standard Partition - Non LVM)
    echo "Khong dung LVM. Resize truc tiep..."
    FILE_SYSTEM_TYPE=$(findmnt / -o FSTYPE -n)
    if [ "$FILE_SYSTEM_TYPE" == "xfs" ]; then
        xfs_growfs /
    elif [ "$FILE_SYSTEM_TYPE" == "ext4" ]; then
        resize2fs ${DISK}${PARTITION_NUM}
    fi
fi

echo "Hoan tat! Dung luong hien tai:"
df -h /
