#!/bin/bash

. ./scripts/INCLUDE.sh

rename_firmware() {
    echo -e "${STEPS} Renaming firmware files..."

    # Validasi direktori firmware
    local firmware_dir="$GITHUB_WORKSPACE/$WORKING_DIR/compiled_images"
    if [[ ! -d "$firmware_dir" ]]; then
        error_msg "Invalid firmware directory: ${firmware_dir}"
    fi

    # Pindah ke direktori firmware
    cd "${firmware_dir}" || {
       error_msg "Failed to change directory to ${firmware_dir}"
    }

    # Pola pencarian dan penggantian
    local search_replace_patterns=(
        # Format: "search|replace"

        # bcm27xx
        "-bcm27xx-bcm2710-rpi-3-ext4-factory|Broadcom_RaspberryPi_3B-Ext4_Factory"
        "-bcm27xx-bcm2710-rpi-3-ext4-sysupgrade|Broadcom_RaspberryPi_3B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2710-rpi-3-squashfs-factory|Broadcom_RaspberryPi_3B-Squashfs_Factory"
        "-bcm27xx-bcm2710-rpi-3-squashfs-sysupgrade|Broadcom_RaspberryPi_3B-Squashfs_Sysupgrade"

        "-bcm27xx-bcm2711-rpi-4-ext4-factory|Broadcom_RaspberryPi_4B-Ext4_Factory"
        "-bcm27xx-bcm2711-rpi-4-ext4-sysupgrade|Broadcom_RaspberryPi_4B-Ext4_Sysupgrade"
        "-bcm27xx-bcm2711-rpi-4-squashfs-factory|Broadcom_RaspberryPi_4B-Squashfs_Factory"
        "-bcm27xx-bcm2711-rpi-4-squashfs-sysupgrade|Broadcom_RaspberryPi_4B-Squashfs_Sysupgrade"
        
        "-bcm27xx-bcm2712-rpi-5-ext4-factory|Broadcom_RaspberryPi_5-Ext4_Factory"
        "-bcm27xx-bcm2712-rpi-5-ext4-sysupgrade|Broadcom_RaspberryPi_5-Ext4_Sysupgrade"
        "-bcm27xx-bcm2712-rpi-5-squashfs-factory|Broadcom_RaspberryPi_5-Squashfs_Factory"
        "-bcm27xx-bcm2712-rpi-5-squashfs-sysupgrade|Broadcom_RaspberryPi_5-Squashfs_Sysupgrade"
        
        # Allwinner
        "-h5-orangepi-pc2-|Allwinner_OrangePi_PC2"
        "-h5-orangepi-prime-|Allwinner_OrangePi_Prime"
        "-h5-orangepi-zeroplus-|Allwinner_OrangePi_ZeroPlus"
        "-h5-orangepi-zeroplus2-|Allwinner_OrangePi_ZeroPlus2"
        "-h6-orangepi-1plus-|Allwinner_OrangePi_1Plus"
        "-h6-orangepi-3-|Allwinner_OrangePi_3"
        "-h6-orangepi-3lts-|Allwinner_OrangePi_3LTS"
        "-h6-orangepi-lite2-|Allwinner_OrangePi_Lite2"
        "-h616-orangepi-zero2-|Allwinner_OrangePi_Zero2"
        "-h618-orangepi-zero2w-|Allwinner_OrangePi_Zero2W"
        "-h618-orangepi-zero3-|Allwinner_OrangePi_Zero3"
        
        # Rockchip
        "-rk3566-orangepi-3b-|Rockchip_OrangePi_3B"
        "-rk3588s-orangepi-5-|Rockchip_OrangePi_5"
        "-firefly_roc-rk3328-cc-|Firefly-RK3328"
        
        # friendlyarm
        "friendlyarm_nanopi-r2s-|Friendlyarm-Nanopi-r2s"
        "friendlyarm_nanopi-r3s-|Friendlyarm-Nanopi-r3s"
        "friendlyarm_nanopi-r4s-|Friendlyarm-Nanopi-r4s"
        "friendlyarm_nanopi-r5s-|Friendlyarm-Nanopi-r5s"
        "friendlyarm_nanopi-r6s-|Friendlyarm-Nanopi-r6s"
        
        # Amlogic ULO
        "-s905x-b860h-|Amlogic-s905x-B860H"
        "-s905x-hg680p-|Amlogic-s905x-HG680P"
        "-s905x2-b860hv5-|Amlogic-s905x2-B860Hv5"
        "-s905x2-hg680-fj-|Amlogic-s905x2-HG680-FJ"
        "-s905x3-|Amlogic-s905x3"
        "-s905x4-|Amlogic-s905x4"
        
        # Amlogic Ophub
        "_s905x_|Amlogic_s905x_HG680P"
        "_s905x-b860h_|Amlogic_s905x_B860H"
        "_s912-nexbox-a1_|Amlogic_s912_NEXBOX_A1"
        "_s905l2_|Amlogic_s905l2_MGV_M301A"
        "_s905x2-x96max-2g_|Amlogic_s905x2-x96Max2Gb"
        "_s905x2_|Amlogic_s905x2_x96Max-4Gb"
        "_s905x2-b860h-v5_|Amlogic_s905x2_B860Hv5"
        "_s905x2-hg680-fj_|Amlogic_s905x2_HG680-FJ"
        "_s905x3-x96air_|Amlogic_s905x3-X96Air100M"
        "_s905x3-x96air-gb_|Amlogic_s905x3-x96Air1Gbps"
        "_s905x3-hk1_|Amlogic_s905x3-HK1BOX"
        "_s905x3_|Amlogic_s905x3_X96MAX+_100Mb"
        "_s905x3-x96max_|Amlogic_s905x3_X96MAX+_1Gb"
        
        # Allwinner Ophub
        "_allwinner_orangepi-3_|Orangepi_3"
        "_allwinner_orangepi-zplus_|Orangepi_ZeroPlus"
        "_allwinner_orangepi-zplus2_|Orangepi_Zero_Plus2"
        "_allwinner_orangepi-zero2_|Orangepi_Zero2"
        "_allwinner_orangepi-zero3_|Orangepi_Zero_3"
        
        # RK3318 Ophub
        "_rk3318-box_|RK3318-Box"
        # RK3328 Ophub
        "_renegade-rk3328_|Renegade_Firefly-RK3328"
        
        # friendlyarm Ophub
        "_nanopi-r5s_|Nanopi-r5s"
        "_nanopi-r5c_|Nanopi-r5c"
        
        # x86_64
        "x86-64-generic-ext4-combined-efi|X86_64_Generic_Ext4_Combined_EFI"
        "x86-64-generic-ext4-combined|X86_64_Generic_Ext4_Combined"
        "x86-64-generic-ext4-rootfs|X86_64_Generic_Ext4_Rootfs"
        "x86-64-generic-squashfs-combined-efi|X86_64_Generic_Squashfs_Combined_EFI"
        "x86-64-generic-squashfs-combined|X86_64_Generic_Squashfs_Combined"
        "x86-64-generic-squashfs-rootfs|X86_64_Generic_Squashfs_Rootfs"
        "x86-64-generic-rootfs|X86_64_Generic_Rootfs"
    )

   for pattern in "${search_replace_patterns[@]}"; do
        local search="${pattern%%|*}"
        local replace="${pattern##*|}"

        for file in *"${search}"*.img.gz; do
            if [[ -f "$file" ]]; then
                local kernel=""
                if [[ "$file" =~ k[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9-]+)? ]]; then
                    kernel="${BASH_REMATCH[0]}"
                fi
                local new_name
                if [[ -n "$kernel" ]]; then
                    new_name="${OP_BASE}-${BRANCH}-${replace}-${kernel}-${TUNNEL}-Build-By-Fidz.img.gz"
                else
                    new_name="${OP_BASE}-${BRANCH}-${replace}-${TUNNEL}-Build-By-Fidz.img.gz"
                fi
                echo -e "${INFO} Renaming: $file → $new_name"
                mv "$file" "$new_name" || {
                    echo -e "${WARN} Failed to rename $file"
                    continue
                }
            fi
        done
        for file in *"${search}"*.tar.gz; do
            if [[ -f "$file" ]]; then
                local new_name
                new_name="${OP_BASE}-${BRANCH}-${replace}-${TUNNEL}-Build-By-Fidz.tar.gz"
                echo -e "${INFO} Renaming: $file → $new_name"
                mv "$file" "$new_name" || {
                    echo -e "${WARN} Failed to rename $file"
                    continue
                }
            fi
        done
    done

    sync && sleep 3
    echo -e "${INFO} Rename operation completed."
}

rename_firmware