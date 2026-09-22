#!/bin/bash

echo "Starting Hyprland dotfiles dependency installation..."

# 1. Update the system
echo "Updating system..."
sudo pacman -Syu --noconfirm

# 2. Install base-devel and git (required for AUR and cloning)
echo "Installing base-devel and git..."
sudo pacman -S --needed base-devel git --noconfirm

# 3. Install 'yay' (AUR helper) if it isn't already installed
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git ~/yay
    cd ~/yay
    makepkg -si --noconfirm
    cd ~
    rm -rf ~/yay
else
    echo "yay is already installed."
fi

# 4. List of official Pacman packages
PACMAN_PACKAGES=(
    hyprland
    waybar
    rofi-wayland       
    fish
    kitty              
    thunar             
    grim               
    slurp              
    wl-clipboard       
    cliphist           
    brightnessctl      
    playerctl          
    wlogout            
    wireplumber        
    pipewire-audio     
    ttf-jetbrains-mono-nerd 
    xdg-desktop-portal-hyprland 
    polkit-kde-agent
    xdg-user-dirs      # Required to create default user folders
    nwg-look           # Wayland GTK settings manager
    materia-gtk-theme  # Alternative dark GTK theme
    gnome-themes-extra # Provides the official Adwaita and Adwaita-dark GTK themes
)

# 5. List of AUR packages
AUR_PACKAGES=(
    brave-bin          
    hyprshutdown       
)

# 6. Install Pacman packages
echo "Installing official packages..."
sudo pacman -S --needed "${PACMAN_PACKAGES[@]}" --noconfirm

# 7. Install AUR packages
echo "Installing AUR packages..."
yay -S --needed "${AUR_PACKAGES[@]}" --noconfirm

# 8. Create standard user directories (Downloads, Pictures, Documents, etc.)
echo "Creating standard user folders..."
xdg-user-dirs-update

# 9. Change default shell to fish
echo "Changing default shell to fish..."
# We use the current user ($USER) to ensure it changes it for you, not root
sudo chsh -s $(which fish) $USER

# 10. Clone your dotfiles repository
echo "Cloning dotfiles from arjo321..."
# This checks if the folder already exists to prevent git errors
if [ ! -d "$HOME/dotfile" ]; then
    git clone https://github.com/arjo321/dotfile.git ~/dotfile
    echo "Dotfiles cloned to ~/dotfile"
else
    echo "Directory ~/dotfile already exists. Skipping clone."
fi

echo "----------------------------------------"
echo "Installation complete!" 
echo "Your standard folders (Downloads, Pictures, etc.) are ready."
echo "Your dotfiles are downloaded to ~/dotfile."
echo "Adwaita Dark has been installed."
echo "Please restart your computer or log out and log back in."
echo "----------------------------------------"
