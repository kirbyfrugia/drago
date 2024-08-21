sudo dnf groupinstall "Development Tools" "Development Libraries"
sudo dnf install freetype-devel
sudo dnf install openal-soft-devel
sudo dnf install SDL2-devel
sudo dnf install pulseaudio-libs-devel
sudo dnf install gtk3-devel
sudo dnf install libgudev-devel
sudo dnf install cmake
sudo dnf install make automake gcc gcc-c++

git clone https://bitbucket.org/piciji/denise.git
cd denise/
cmake -B builds/release [-DCMAKE_INSTALL_PREFIX=~/.local] [-DINSTALL_FILE_ASSOCIATIONS=1]
cmake --build builds/release -j 2

sudo cmake --build builds/release --target install
# sudo cmake --build builds/release --target uninstall




