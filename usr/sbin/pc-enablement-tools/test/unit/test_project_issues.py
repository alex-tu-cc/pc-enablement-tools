#!/usr/bin/env python
# -*- coding: utf-8 -*-

import unittest
import subprocess
import os

class SimplisticTest(unittest.TestCase):
    def setrUp(self):
        os.system("collect-logs.sh");

    def test_mac_address(self):
        result = subprocess.run(['dmesg'],stdout=subprocess.PIPE, input="dmesg")
        #result = subprocess.run(['grep', 'MAC'],stdout=subprocess.PIPE, input="dmesg")
        result.stdout.decode('utf-8')
        self.assertNotIn("ff:ff:ff",os.system("dmesg | grep MAC"))

import subprocess

# way 1
result = subprocess.run(['sudo', 'apt-get', 'update'],stdout=subprocess.PIPE)
result.stdout.decode('utf-8')
# way 2
cmd = ['awk', 'length() > 5']
input = 'foo\nfoofoo\n'.encode('utf-8')
result = subprocess.run(cmd, stdout=subprocess.PIPE, input=input)
result.stdout.decode('utf-8')


if __name__ == '__main__':
    unittest.main()
