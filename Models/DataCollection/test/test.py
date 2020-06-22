from selenium import webdriver
from selenium.webdriver.common import action_chains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.common.by import By

import time

# archive availability API http://archive.org/wayback/available?url=example.com

def wait_for_id(driver,id,timeout=1000):
    WebDriverWait(driver, timeout).until(expected_conditions.presence_of_element_located((By.ID, id)))

def fill_field(driver,id,value,by_id = True):
    if by_id:
        elem = driver.find_element_by_id(id)
        elem.clear()
        elem.send_keys(value)
    else: # else by name
        elem = driver.find_element_by_name(id)
        elem.clear()
        elem.send_keys(value)


profile=webdriver.FirefoxProfile()
profile.set_preference('network.proxy.type', 1)
profile.set_preference("network.proxy.https","127.0.0.1")
profile.set_preference("network.proxy.https_port",9050)
profile.set_preference("network.proxy.socks", "127.0.0.1")
profile.set_preference("network.proxy.socks_port",9050)
profile.set_preference("network.proxy.socks_version", 5)
profile.update_preferences()

driver = webdriver.Firefox(firefox_profile=profile)

prefixurl = open('prefixurl','r').readlines()[0].replace('\n','')
targeturl = open('targeturl','r').readlines()[0].replace('\n','')

start = time.time()

for id in range(120100,120110):
    print('Getting id '+str(id))
    driver.get(prefixurl)
    #wait_for_id(driver,"recaptcha-anchor")

    WebDriverWait(driver, 1000).until(expected_conditions.presence_of_element_located((By.NAME, 'url_preload')))
    fill_field(driver,'url_preload',targeturl+str(id),False)
    #action_chains.ActionChains(driver).click(driver.find_element_by_id("recaptcha-anchor")).perform()

    #driver.find_element_by_name(id).send_keys(Keys.ENTER)
    driver.find_element_by_class_name('web-save-button').send_keys(Keys.ENTER)
    time.sleep(5)
    #WebDriverWait(driver, 1000).until(expected_conditions.presence_of_element_located((By.CLASS_NAME, 'web-save-button')))
    driver.find_element_by_class_name('web-save-button').send_keys(Keys.ENTER)
    #wait_for_id(driver,'spn-msg')
    #print(driver.find_element_by_id('spn-msg').get_attribute('innerHTML'))
    WebDriverWait(driver, 1000).until(expected_conditions.presence_of_element_located((By.PARTIAL_LINK_TEXT, '/web/')))

print('Total time = '+str(time.time() - start))
