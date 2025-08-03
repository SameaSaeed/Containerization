import pytest
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.desired_capabilities import DesiredCapabilities

@pytest.fixture(scope="session")
def driver():
    """Create a Selenium WebDriver instance for testing."""
    
    # Configure Chrome options for containerized environment
    chrome_options = Options()
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")
    
    # Set up desired capabilities
    capabilities = DesiredCapabilities.CHROME
    capabilities['acceptSslCerts'] = True
    capabilities['acceptInsecureCerts'] = True
    
    # Connect to remote Selenium hub running in Docker
    driver = webdriver.Remote(
        command_executor='http://localhost:4444/wd/hub',
        desired_capabilities=capabilities,
        options=chrome_options
    )
    
    # Set implicit wait time
    driver.implicitly_wait(10)
    
    yield driver
    
    # Cleanup: quit the driver after tests
    driver.quit()

@pytest.fixture(scope="function")
def screenshot_on_failure(request, driver):
    """Take screenshot on test failure."""
    yield
    if request.node.rep_call.failed:
        screenshot_name = f"screenshots/failed_{request.node.name}.png"
        driver.save_screenshot(screenshot_name)
        print(f"Screenshot saved: {screenshot_name}")

@pytest.hookimpl(tryfirst=True, hookwrapper=True)
def pytest_runtest_makereport(item, call):
    """Hook to capture test results for screenshot functionality."""
    outcome = yield
    rep = outcome.get_result()
    setattr(item, "rep_" + rep.when, rep)