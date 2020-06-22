
from selenium import webdriver
from selenium.webdriver.common import action_chains
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select

import utils

def get_profile():
    profile=webdriver.FirefoxProfile()
    profile.set_preference('network.proxy.type', 1)
    profile.set_preference("network.proxy.https","127.0.0.1")
    profile.set_preference("network.proxy.https_port",9050)
    profile.set_preference("network.proxy.socks", "127.0.0.1")
    profile.set_preference("network.proxy.socks_port",9050)
    profile.set_preference("network.proxy.socks_version", 5)
    return(profile)


def initialize():
    """
    Reset the driver
    """
    profile=get_profile()
    driver = webdriver.Firefox(firefox_profile=profile)
    return(driver)


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





def fill_field(driver,id,value,by_id = True):
    if by_id:
        elem = driver.find_element_by_id(id)
        elem.clear()
        elem.send_keys(value)
    else: # else by name
        elem = driver.find_element_by_name(id)
        elem.clear()
        elem.send_keys(value)

def click_validate(driver,id):
    driver.find_element_by_name(id).send_keys(Keys.ENTER)


def wait_for_id(driver,id,timeout=1000,by_id = True):
    if by_id:
        WebDriverWait(driver, timeout).until(expected_conditions.presence_of_element_located((By.ID, id)))
    else:
        WebDriverWait(driver, timeout).until(expected_conditions.presence_of_element_located((By.NAME, id)))


def wait_and_click(driver, id,timeout=1000):
    wait_for_id(driver,id,timeout)
    action_chains.ActionChains(driver).click(driver.find_element_by_id(id)).perform()

def select(driver,id,value):
    Select(driver.find_element_by_id(id)).select_by_value(value)


def save_id(driver,prefixurl,targeturl,id):
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
    # TODO verify that spn-title is present
    driver.find_element_by_class_name('web-save-button').send_keys(Keys.ENTER)
    #wait_for_id(driver,'spn-msg')
    #print(driver.find_element_by_id('spn-msg').get_attribute('innerHTML'))
    WebDriverWait(driver, 1000).until(expected_conditions.presence_of_element_located((By.PARTIAL_LINK_TEXT, '/web/')))
