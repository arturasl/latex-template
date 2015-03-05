#!/bin/bash

sudo apt-get -y update
# core stuff
sudo apt-get install -y make vim-gnome patch unzip software-properties-common git
sudo apt-get install -y openjdk-7-jre-headless
# latex stuff
sudo apt-get install -y texlive-full
if [ ! -d /home/vagrant/texmf/tex/latex/standalone ]; then
	cd /home/vagrant
	mkdir texmf/
	cd texmf
	wget http://mirrors.ctan.org/install/macros/latex/contrib/standalone.tds.zip
	unzip standalone.tds.zip
	rm standalone.tds.zip
fi
# workers - used to convert various formats to pdf
sudo apt-get install -y dia inkscape gnuplot imagemagick xcftools
sudo add-apt-repository -y ppa:gviz-adm/graphviz-dev && sudo apt-get -y update && sudo apt-get install -y graphviz

if [ ! -f /usr/bin/umlet ]; then
	cd /home/vagrant
	mkdir Builds
	cd Builds
	wget http://www.umlet.com/umlet_13_0/umlet_13.0.zip -O umlet.zip
	unzip umlet.zip
	rm -rf umlet.zip
	sudo tee /usr/bin/umlet <<EOF
#!/bin/bash
java -jar /home/vagrant/Builds/Umlet/umlet.jar "\$@"
EOF
	sudo chmod a+x /usr/bin/umlet
fi
# for previewing results
sudo apt-get install -y evince
# pygmentize & lexer for pseudocode
sudo apt-get install -y python python3 python-setuptools
sudo easy_install Pygments
if [ -z "$(pygmentize -L | grep 'pseudo:$')" ]; then
	cd /vagrant/latex-template/scripts/lexer/
	sudo python setup.py develop
fi
sudo patch /usr/local/lib/python2.7/dist-packages/Pygments-1.6-py2.7.egg/pygments/formatters/latex.py < /vagrant/latex-template/scripts/lexer/pygments.patch

# fonts
if [ ! -d /usr/local/share/fonts/truetype/palemonas ]; then
	wget http://www.vlkk.lt/i/u/file/Palemonas-2_1.zip && unzip Palemonas-2_1.zip && rm -f Palemonas-2_1.zip
	sudo mkdir -p /usr/local/share/fonts/truetype/palemonas
	sudo cp Palemonas-2.1/*.ttf /usr/local/share/fonts/truetype/palemonas
	sudo fc-cache
	rm -rf Palemonas*
fi
