#!/usr/bin/env python
# -*- coding: utf-8 -*-
from argparse import ArgumentParser
import logging
import subprocess
import fileinput
from shutil import copyfile
import os

class Tool(object):

    """Docstring for MyClass. """
    data1="value1"
    def __init__(self):
        """TODO: to be defined1. """

    def enable_src(self,onoff):
        """ remove '#' from source.list """
        target_file='/etc/apt/sources.list'
        with fileinput.FileInput(target_file, inplace=True, backup='.bak') as file:
            if onoff == "on":
                for line in file:
                    print(line.replace("#deb-src", 'deb-src'),end='')
                subprocess.run(['sudo', 'apt-get', 'update'])
            else:
                copyfile(target_file+".bak",target_file)
                subprocess.run(['sudo', 'apt-get', 'update'])

    def prepare_debuild_env(self):
        try:
            subprocess.run(['sudo', 'apt-get', 'install', '-y', 'devscripts', 'equivs', 'pkg-create-dbgsym']);
        except:
            logging.info("prepare_debuild_env get excep {}".format(sys.exc_info()[0]) )

def main():
    parser = ArgumentParser(prog="tools")
    parser.add_argument('--prepare_debuild_env', action="store_true",help="install all needed for debuild packages")
    parser.add_argument('--install_build_deps', action="store_true",help="enable source ppa then install all dependence under ./debian, then you can easily debuild -i -b -uc -us")
    parser.add_argument("-l", "--log", dest="logLevel", choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], help="Set the logging level")
    args = parser.parse_args()
    tool=Tool()
    if args.logLevel:
        logging.basicConfig(level=logging.getLevelName(args.logLevel))
    if args.install_build_deps:
        tool.enable_src("on")
        tool.prepare_debuild_env()
        os.system('sudo mk-build-deps --install --tool "apt-get -y" --build-dep debian/control')
    

if __name__ == "__main__":
    main()
