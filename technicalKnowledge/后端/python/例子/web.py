import requests
import os
from bs4 import BeautifulSoup

#数据存储
fo = open("./rcp.html",'a',encoding="utf-8")

response = requests.get('http://localhost:8888/rcp')
response.encoding='utf-8'
soup = BeautifulSoup(response.text, 'html.parser')

fo.write(soup.select("html")[0].text)
fo.close()