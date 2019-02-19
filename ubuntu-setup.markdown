# Ubuntu setup guide

- [Packages to install](#packages-to-install)
- [Configurations](#configurations)
- [Python](#python)
- [Graphic Drivers](#graphic-drivers)
- [Thinkpad Trackpoint configuration](#thinkpad-trackpoint-configuration)

Most of the configs needed are already in https://github.com/garylirocks/dotfiles

## Packages to install

- vim

  only vim.tiny is installed by default, we need `vim-gnome` (it's compiled with `+xterm_clipboard` flag), which enables you to copy text to the system clipboard

  ```sh
  sudo apt-get install vim-gnome

  # install exuberant-ctags
  sudo apt-get install exuberant-ctags
  ```

- VirtualBox

  ```sh
  wget -q http://download.virtualbox.org/virtualbox/debian/oracle_vbox.asc -O- | sudo apt-key add -
  sudo vi /etc/apt/sources.list.d/virtualbox.list
  # input this line ('raring' need be changed to your version code):
  # deb http://download.virtualbox.org/virtualbox/debian raring contrib
  sudo apt-get update
  sudo apt-get install virtualbox-4.2

  # vbox will create a new group, add your user to it
  sudo usermod -G vboxusers -a gary

  # you need "Oracle VM VirtualBox Extension Pack" to enable USB support in guest OS
  # download, install: 'File -> Preferences -> Extensions'
  ```

- Calibre - ebook management

  ```sh
  # ref: http://calibre-ebook.com/download_linux
  # install to /opt (change the install_dir if you need)
  sudo python -c "import sys; py3 = sys.version_info[0] > 2; u = __import__('urllib.request' if py3 else 'urllib', fromlist=1); exec(u.urlopen('http://status.calibre-ebook.com/linux_installer').read()); main(install_dir='/opt')"
  ```

- Input method

  ```sh
  # 'System Settings' -> 'Language Support' -> change input method to 'fcitx'
  sudo add-apt-repository ppa:fcitx-team/nightly
  sudo apt-get update
  sudo apt-get install fcitx-sogoupinyin

  # install google pinyin
  sudo apt-get install ibus-googlepinyin

  # set preferences
  ibus-setup
  ```

## Configurations

- Firefox

  - Setup sync;
  - Disable some pre-installed addons;

- Remove the email icon on top bar

  Ref: http://askubuntu.com/a/533836/159823

- Add a shortcut for moving windows between multiple monitors

  ```sh
  sudo apt-get install compizconfig-settings-manager compiz-plugins
  ```

  Then use 'Put' in 'Window Management' to set a shortcut for moving window between monitors

- Install custom fonts

  Put the font files (.ttf) in `~/.fonts`

- Config startup applications

  - There is a `Startup Applications` GUI tool, the config files are in `~/.config/autostart/`;
  - If you want a sudo service to autostart, add the command to `/etc/rc.local`;

- Customize the Launcher

  ```sh
  # show Launcher items
  gsettings get com.canonical.Unity.Launcher favorites
  # ['firefox.desktop', 'google-chrome.desktop', 'virtualbox.desktop', 'nautilus-home.desktop', 'gnome-control-center.desktop']
  ```

  `.desktop` files are usually stored in `~/.local/share/applications/` or `/usr/share/applications/`, you can edit those files, once a `.desktop` file is placed one of the folders, you can find them through Dash, and drag them to the Launcher

## Python

**NOTICE:** Seems like if installing python in a customized location, the readline module is not enabled, which is cumbersome for interaction at the command line

```sh
# download python tarball, extract it
cd Python-3.3.2/
./configure --prefix='/opt/python3.3.2'
make
sudo make install

# add python3.3 to path
sudo ln -s /opt/python3.3.2/bin/python3.3 /usr/bin/python3.3

# install setuptools
wget https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -O - | sudo python3.3
sudo ln -s /opt/python3.3.2/bin/easy_install-3.3 /usr/bin/easy_install-3.3

# install pip
sudo easy_install-3.3 pip
sudo ln -s /opt/python3.3.2/bin/pip-3.3 /usr/bin/pip-3.3

# ipython
sudo pip-3.3 install ipython

# MySQLdb module
sudo apt-get install python-mysqldb

# Tkinter
apt-cache search python-tk

# pylab, matplotlib
# pre-built package: python-matplotlib
```

## Graphic Drivers

Nvidia Drivers:

- http://www.webupd8.org/2016/06/how-to-install-latest-nvidia-drivers-in.html
- http://www.geforce.com/drivers

## Thinkpad Trackpoint configuration

Use middle button for scrolling

ref: http://www.thinkwiki.org/wiki/How_to_configure_the_TrackPoint

- Use `xinput list` to find the device name first, in the following case, the name is `ImPS/2 Generic Wheel Mouse`;

- Create a file `trackpoint-config.sh`;

  ```sh
  xinput set-prop "ImPS/2 Generic Wheel Mouse" "Evdev Wheel Emulation" 1
  xinput set-prop "ImPS/2 Generic Wheel Mouse" "Evdev Wheel Emulation Button" 2
  xinput set-prop "ImPS/2 Generic Wheel Mouse" "Evdev Wheel Emulation Axes" 6 7 4 5
  ```

- Use it as an autostart script;
