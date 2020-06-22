from selenium import webdriver
from selenium.webdriver.common import action_chains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.common.by import By

import time

import navigation,database,utils



driver = navigation.initialize()

prefixurl = utils.read('prefixurl')
targeturl = utils.read('targeturl')

start = time.time()

for id in range(120100,120110):
    # TODO check limit: 15/min ? did less; total number per day?
    navigation.save_id(driver,prefixurl,targeturl,id)

print('Total time = '+str(time.time() - start))
