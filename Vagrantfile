Vagrant.configure("2") do |config|

  config.vm.boot_timeout = 600

  # DC01
  config.vm.define "dc01" do |dc01|
    dc01.vm.box = "gusztavvargadr/windows-server-2025-standard"
    dc01.vm.box_version = "2607.0.0"

    dc01.vm.network "private_network", ip: "192.168.100.10"

    dc01.vm.communicator = "winrm"
    dc01.winrm.username = "vagrant"
    dc01.winrm.password = "vagrant"

    dc01.vm.provider "vmware_desktop" do |vmware|
      vmware.force_vmware_license = "workstation"
      vmware.memory = 5120
      vmware.cpus = 2
      vmware.gui = true
    end

    dc01.vm.provision "shell",
      path: "scripts/lang.ps1"

    dc01.vm.provision "shell",
      path: "scripts/dc01.ps1"

    dc01.vm.provision "shell",
      path: "scripts/dc01-AD.ps1",
      reboot: true
  end

  # SRV01
  config.vm.define "srv01" do |srv01|
    srv01.vm.box = "gusztavvargadr/windows-server-2025-standard"
    srv01.vm.box_version = "2607.0.0"

    srv01.vm.network "private_network", ip: "192.168.100.20"

    srv01.vm.provider "vmware_desktop" do |vmware|
      vmware.force_vmware_license = "workstation"
      vmware.memory = 4096
      vmware.cpus = 2
      vmware.gui = true
    end

    srv01.vm.provision "shell",
      path: "scripts/lang.ps1"

    srv01.vm.provision "shell",
      path: "scripts/srv01.ps1"

    srv01.vm.provision "shell",
      path: "scripts/dcjoin.ps1",
      reboot: true
  end

  # Client01
  config.vm.define "client01" do |client01|
    client01.vm.box = "baunegaard/win11pro-en"
    client01.vm.box_version = "1.0.0"

    client01.vm.network "private_network", ip: "192.168.100.30"

    client01.vm.provider "vmware_desktop" do |vmware|
      vmware.force_vmware_license = "workstation"
      vmware.memory = 4096
      vmware.cpus = 2
      vmware.gui = true
    end

    client01.vm.provision "shell",
      path: "scripts/lang.ps1"

    client01.vm.provision "shell",
      path: "scripts/client01.ps1"

    client01.vm.provision "shell",
      path: "scripts/dcjoin.ps1",
      reboot: true
  end

  # Kali
  config.vm.define "kali1" do |kali|
    kali.vm.box = "kalilinux/rolling"
    kali.vm.box_version = "2026.2.0"

    kali.vm.network "private_network", ip: "192.168.100.40"

    kali.vm.communicator = "ssh"

    kali.vm.provider "vmware_desktop" do |vmware|
      vmware.force_vmware_license = "workstation"
      vmware.memory = 5120
      vmware.cpus = 2
      vmware.gui = true
    end
  end
end
