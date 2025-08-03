import pytest
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

@pytest.fixture(scope="session", params=["chrome", "firefox"])
def driver(request):
    """Create a Selenium WebDriver instance for cross-browser testing."""
    
    browser = request.param
    selenium_hub_url = os.getenv('SELENIUM_HUB_URL', 'http://localhost:4444/wd/hub')
    
    if browser == "chrome":
        chrome_options = Options()
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--window-size=1920,1080")
        
        capabilities = DesiredCapabilities.CHROME
        capabilities['acceptSslCerts'] = True
        capabilities['acceptInsecureCerts'] = True
        
        driver = webdriver.Remote(
            command_executor=selenium_hub_url,
            desired_capabilities=capabilities,
            options=chrome_options
        )
    
    elif browser == "firefox":
        firefox_options = FirefoxOptions()
        firefox_options.add_argument("--width=1920")
        firefox_options.add_argument("--height=1080")
        
        capabilities = DesiredCapabilities.FIREFOX
        capabilities['acceptSslCerts'] = True
        capabilities['acceptInsecureCerts'] = True
        
        driver = webdriver.Remote(
            command_executor=selenium_hub_url,
            desired_capabilities=capabilities,
            options=firefox_options
        )
    
    driver.implicitly_wait(10)
    yield driver
    driver.quit()

@pytest.fixture(autouse=True)
def test_info(request):
    """Print test information."""
    print(f"\n--- Running test: {request.node.name} ---")
    yield
    print(f"--- Completed test: {request.node.name} ---")