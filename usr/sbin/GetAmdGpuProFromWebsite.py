#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import requests
from bs4 import BeautifulSoup
import re
base_url = 'http://support.amd.com/en-us/kb-articles/Pages/AMDGPU-PRO-Install.aspx'

get_page = requests.get(base_url)
# print web page content
# print(get_page.text)

# parse content by BeautifulSoup
soup = BeautifulSoup(get_page.text, 'html.parser')
download_url = soup.findAll(href=re.compile("ubuntu"))[0].get('href')
print(download_url)


