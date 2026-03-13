#!/usr/bin/env bash
# NECRODERMIS — scripts/functions/gpu_drivers.sh
# Component: install_gpu_drivers

install_gpu_drivers() {
    print_section "GPU DRIVERS  //  OPTIC ARRAY SUBSTRATE"

    local GPU
    GPU="$(detect_gpu)"
    print_info "Optic array detected  //  ${GPU}"

    case "$GPU" in
        amd)
            necro_pkg "gpu-drivers" \
                mesa lib32-mesa \
                vulkan-radeon lib32-vulkan-radeon \
                libva-mesa-driver lib32-libva-mesa-driver \
                mesa-vdpau lib32-mesa-vdpau \
                xf86-video-amdgpu
            print_ok "AMD optic array armed  ${DG}//  mesa · vulkan-radeon · libva${NC}"
            ;;
        nvidia)
            local DISTRO
            DISTRO="$(detect_distro)"
            if [[ "$DISTRO" == "cachyos" ]]; then
                necro_pkg "gpu-drivers" \
                    nvidia-open-dkms nvidia-utils lib32-nvidia-utils \
                    nvidia-settings opencl-nvidia
            else
                necro_pkg "gpu-drivers" \
                    nvidia-dkms nvidia-utils lib32-nvidia-utils \
                    nvidia-settings opencl-nvidia
            fi
            # Enable DRM kernel mode setting
            if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub 2>/dev/null; then
                sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' \
                    /etc/default/grub
                sudo grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null
            fi
            print_ok "NVIDIA optic array armed  ${DG}//  dkms · utils · opencl${NC}"
            ;;
        intel)
            necro_pkg "gpu-drivers" \
                mesa lib32-mesa \
                vulkan-intel lib32-vulkan-intel \
                intel-media-driver libva-intel-driver
            print_ok "Intel optic array armed  ${DG}//  mesa · vulkan-intel · media-driver${NC}"
            ;;
        unknown)
            print_err "Optic array unidentified  //  skipping driver install"
            print_info "Install GPU drivers manually after reboot"
            necro_log "SKIP" "gpu-drivers" "GPU undetected — manual install required"
            ;;
    esac
}
