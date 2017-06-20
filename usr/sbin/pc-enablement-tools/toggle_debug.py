#!/usr/bin/env python
# -*- coding: utf-8 -*-
# https://stackoverflow.com/questions/14097061/easier-way-to-enable-verbose-logging
import argparse
import logging
import fileinput
from shutil import copyfile


class toggle_debug(object):

    """Docstring for MyClass. """
    data1="value1"
    # the available target also samw as the member function.
    available_target=['serial_console', 'persistent_journal', 'modemmanager_debug']
    def __init__(self, debug_targets=None):
        """TODO: to be defined1. """

    def serial_console(self,onoff):
        logging.info("toggling serial console {}".format(onoff))
        with fileinput.FileInput("/etc/default/grub", inplace=True, backup='.bak') as file:
            if onoff == "on":
                for line in file:
                    print(line.replace("quiet splash", 'debug ignore_loglevel initcall_debug no_console_suspend=1 console=tty0 console=ttyS0,115200n8'),end='')
            else:
               copyfile("/etc/default/grub.bak","/etc/default/grub.bak")

    def persistent_journal(self, onoff):
        logging.info("toggling {} {}".format("persistent_journal",onoff))
        target_file="/etc/systemd/journald.conf"
        with fileinput.FileInput(target_file, inplace=True, backup='.bak') as file:
            if onoff == "on":
                for line in file:
                    print(line.replace("#Storage=auto", 'Storage=persistent'),end='')
            else:
               copyfile(target_file+".bak",target_file)

    def modemmanager_debug(self, onoff):
        logging.info("toggling {} {}".format("modemmanager_debug",onoff))




def main():
    parser = argparse.ArgumentParser(description='this prog is used to enable debug message for each part')
    parser.add_argument("-l", "--log", dest="logLevel", choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], help="Set the logging level")
    parser.add_argument("-e", "--enable", dest="enable_debug_target", choices=toggle_debug.available_target, action='append', help="Set the logging level")
    parser.add_argument("-d", "--disable", dest="disable_debug_target", choices=toggle_debug.available_target, action='append', help="disable the logging level")

    args = parser.parse_args()
    if args.logLevel:
        logging.basicConfig(level=logging.getLevelName(args.logLevel))

    print("enable: {}".format(args.enable_debug_target));
    td=toggle_debug()
#    td.serial_console("on");
    
    if args.enable_debug_target is not None:
        for target in  args.enable_debug_target:
            eval("td.{}(\"on\")".format(target))

    if args.disable_debug_target is not None:
        for target in args.disable_debug_target:
            eval("td.{}(\"off\")".format(target))


if __name__ == "__main__":
    main()
