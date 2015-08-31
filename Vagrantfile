# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	config.vm.box = "ubuntu/trusty32"
	config.ssh.forward_x11 = true

	config.vm.provider :virtualbox do |vb|
		# use 1gb of ram as it seams with out it xelatex fails with "./src/tex/main.tex:28: I can't write on file `main.pdf'.`"
		vb.customize ["modifyvm", :id, "--memory", "1024"]
	end

	config.vm.synced_folder "..", "/vagrant"
	config.vm.provision :shell, :path => "scripts/setupvm.bash"
	config.vm.hostname = "latex"

end

