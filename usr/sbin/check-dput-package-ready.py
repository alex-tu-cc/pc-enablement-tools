#!/usr/bin/python
# -*- coding: utf-8 -*-
#
# Copyright (C) 2011 Canonical, Ltd.
#
# Author: alex tu <alex.tu@canonical.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import argparse
import httplib
from launchpadlib.launchpad import Launchpad
import os.path
import os
import re
import sys
import urllib
import subprocess
import time
import logging

DESCRIPTION = 'Check whether the package you dput is ready '

class AuthenticatedURLopener(urllib.FancyURLopener):
    MAX_RETRIES = 5
    def __init__(self, username, password):
        urllib.FancyURLopener.__init__(self)
        self.username = username
        self.password = password
        self.retries = 0

    def prompt_user_passwd(self, host, realm):
        return (self.username, self.password)

    def http_error_401(self, url, fp, errcode, errmsg, headers, data=None):
        self.retries = self.retries + 1
        if self.retries > AuthenticatedURLopener.MAX_RETRIES:
            raise IOError(errcode, errmsg)
        else:
            return urllib.FancyURLopener.http_error_401(self, url, fp, errcode,
                                                        errmsg, headers, data)

class CheckDputPckageReady(object):

    """ class which could be used to help the waiting time after dput package.  """
    ppa=None;
    credental_application=None;
    binary_packages={};
    binary_package_got={};
    date_after="2017-06-01"
    polling_interval=10;
    def __init__(self,ppa, credental_application):
        """TODO: to be defined1. """
        self.ppa=ppa;
        self.credental_application=credental_application;


    def append_binary_packages(self, package_name, package_ver):
        """
        to append binary package name to waiting list
        """
        self.binary_package_name.updat(package_name, package_ver)
        pass

    def set_date_after(self, date_after):
        """
        :date_after check packages generated after this date, the format is $years-$mon-$day
        """
        self.date_after = date_after
        pass

    def check_ppa_packages(self, binary_packages=None):
        """
        binary_packages is a dic structur = {[package-name:package-verstion]}
        """
        if binary_packages == None:
            binary_packages=self.binary_packages
        binary_package_got = {};
        try:
            cachedir = os.path.join(os.environ["HOME"], ".launchpadlib/cache")
            lp = Launchpad.login_with(args.credental_application, 'production', cachedir, version="devel")
            # ex. ppa:alextu/test1
            url = lp.people[re.split('[:/]',self.ppa)[1]].getPPAByName(name=re.split('/',self.ppa)[1])
            logging.debug("url={}".format(url))
            ppa = lp.load(str(url))
            bin_pkgs = ppa.getPublishedBinaries(created_since_date=self.date_after)
            for bin_pkg in bin_pkgs:
                print('checked {0}'.format(bin_pkg.binary_package_name))
            #    print('self_link={}'.format(bin_pkg.self_link))
                # this is the download link
                # archive_link=https://api.launchpad.net/devel/~alextu/+archive/ubuntu/modemmanager
                #  wget https://api.launchpad.net/devel/~alextu/+archive/ubuntu/modemmanager/+files/libmbim-glib4_1.12.2-2ubuntu1oem1_amd64.deb
            #    print('archive_link={}'.format(bin_pkg.archive_link))
            #    print('build_link={}'.format(bin_pkg.build_link))
                try:
                    if binary_packages.get(bin_pkg.binary_package_name) == bin_pkg.binary_package_version:
                        self.binary_package_got.update({bin_pkg.binary_package_name:bin_pkg.archive_link+"/+files/"+bin_pkg.binary_package_name+"_"+bin_pkg.binary_package_version+"_amd64.deb"})
                        logging.debug('binary_packages.discard({"bin_pkg.binary_package_name":"bin_pkg.binary_package_version"})')
                        del binary_packages[bin_pkg.binary_package_name]
                        #binary_packages.discard({"bin_pkg.binary_package_name":"bin_pkg.binary_package_version"})
#                    else:
#                        logging.debug("{} != {} ",format(binary_packages.get(bin_pkg.binary_package_name),bin_pkg.binary_package_version))
                except:
                    continue;
            if len(self.binary_package_got) > 0:
                print ('get version {0}'.format(bin_pkg.binary_package_version))
                for item in self.binary_package_got:
                    print("+ {}:{}".format(item, self.binary_package_got[item]))
            if len(binary_packages) > 0:
                print (' some package not ready')
                for item in binary_packages:
                    print("- {}:{}".format(item, binary_packages[item]))
                return False;
            else:
                return True;
        except Exception as e:
            print("get exception {}",format(str(e)));

    def wait(self, binary_packages=None):
        """TODO: Docstring for wait.
        binary_packages is a dic structur = {[package-name,package-verstion]}
        :arg1: TODO
        :returns: TODO

        """
        if binary_packages == None:
            binary_packages = self.binary_packages
        try:
            while self.check_ppa_packages(binary_packages) == False:
                time.sleep(self.polling_interval);
        except Exception as e:
            print("get exception {}",format(str(e)));


    def set_changes_file(self,changes_file):
        with open(changes_file) as fp:
            for line in iter(fp.readline,''):
                if "Binary:" in line:
                    logging.debug("parsing line: {}".format(line))
                    for package in re.split('[ \n]+',line.rstrip()):
                        if package != "Binary:":
                            self.binary_packages.update({package:None})
                            logging.debug("150 binary_packages={}".format(self.binary_packages))
                    continue
                if "Version" in line:
                    logging.debug("parsing line: {}".format(line))
                    version=re.split('[ \n]+',line.rstrip())[1]
                    for item in self.binary_packages:
                        self.binary_packages[item]=version
                    break
        logging.debug("binary_packages={}".format(self.binary_packages))


#        with fileinput.FileInput(changes_fil) as file:
#            for line in file:
#                line.replace("source str","target str")
        pass

    def dput(self, changes_file):
        """
        dput deb changes file to specified ppa

        :changes_file: should be somtehing like xxxx.changes, which could be generated by debuild -s -Sa
        :returns: true = passed

        """
        self.set_changes_file(changes_file)
        subprocess.call(['dput',self.ppa,changes_file])
        pass

    def dput_and_wait(self, changes_file):
        """TODO: Docstring for dput_and_wait.
        wait after dput something

        """
        self.dput(changes_file)
        self.wait()
        pass

    def download(self,binary_package_got=None):
        if binary_package_got == None:
            binary_package_got = self.binary_package_got
        for item in binary_package_got:
            subprocess.call(["wget",binary_package_got[item]])
    pass



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument('-p', '--ppa', required=True,
                        help='the name of ppa, ex.  ppa:alextu/test, then it\'s name is \'test\'')
    parser.add_argument('-d', '--deb', required=False,
                        help='the name of deb package you would like to poll.')
    parser.add_argument('--deb_version', required=False,
                        help='the version of deb package you would like to poll.')

    parser.add_argument('--credental_application',
                        help='the credental application name')

    parser.add_argument('--changes_file',
                        help='the changes_fil name you want to dput')
    parser.add_argument('--download', action="store_true",
                        help='download binary package')

    parser.add_argument("-l", "--log", dest="logLevel", choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'], help="Set the logging level")

    parser.add_argument('-s', '--series', required=True,
                        help='the Ubuntu series the project is based on (e.g. "xenial")')
    parser.add_argument('-a', '--arch', required=True,
                        help='the architecture the project targets (e.g. "amd64")')

    args = parser.parse_args()
    if args.logLevel:
        logging.basicConfig(level=logging.getLevelName(args.logLevel))

    cpr = CheckDputPckageReady(args.ppa, args.credental_application);
    if args.changes_file != None:
        cpr.dput_and_wait(args.changes_file)

    if args.download == True:
        cpr.download()


    os.system("notify_local.sh done")

