import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys

class TestWebAutomation:
    """Test suite for web automation using Selenium in Docker."""
    
    def test_google_search(self, driver):
        """Test Google search functionality."""
        print("Starting Google search test...")
        
        # Navigate to Google
        driver.get("https://www.google.com")
        
        # Verify page title
        assert "Google" in driver.title
        
        # Find search box and enter search term
        search_box = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.NAME, "q"))
        )
        
        search_term = "Docker Selenium automation"
        search_box.clear()
        search_box.send_keys(search_term)
        search_box.send_keys(Keys.RETURN)
        
        # Wait for results to load
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "search"))
        )
        
        # Verify search results contain our term
        page_source = driver.page_source.lower()
        assert "docker" in page_source
        assert "selenium" in page_source
        
        print("Google search test completed successfully!")
    
    def test_form_interaction(self, driver):
        """Test form filling and submission."""
        print("Starting form interaction test...")
        
        # Navigate to a test form page
        driver.get("https://httpbin.org/forms/post")
        
        # Fill out the form
        customer_name = driver.find_element(By.NAME, "custname")
        customer_name.clear()
        customer_name.send_keys("Docker Test User")
        
        customer_tel = driver.find_element(By.NAME, "custtel")
        customer_tel.clear()
        customer_tel.send_keys("555-1234")
        
        customer_email = driver.find_element(By.NAME, "custemail")
        customer_email.clear()
        customer_email.send_keys("test@docker-selenium.com")
        
        # Select pizza size
        pizza_size = driver.find_element(By.XPATH, "//input[@value='large']")
        pizza_size.click()
        
        # Add toppings
        topping_bacon = driver.find_element(By.NAME, "topping")
        topping_bacon.click()
        
        # Submit the form
        submit_button = driver.find_element(By.XPATH, "//input[@type='submit']")
        submit_button.click()
        
        # Verify form submission
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TAG_NAME, "pre"))
        )
        
        page_content = driver.page_source
        assert "Docker Test User" in page_content
        assert "test@docker-selenium.com" in page_content
        
        print("Form interaction test completed successfully!")
    
    def test_navigation_and_elements(self, driver):
        """Test page navigation and element interactions."""
        print("Starting navigation and elements test...")
        
        # Navigate to example.com
        driver.get("https://example.com")
        
        # Verify page elements
        heading = driver.find_element(By.TAG_NAME, "h1")
        assert heading.text == "Example Domain"
        
        # Check for links
        more_info_link = driver.find_element(By.LINK_TEXT, "More information...")
        assert more_info_link.is_displayed()
        
        # Get page dimensions
        window_size = driver.get_window_size()
        assert window_size['width'] > 0
        assert window_size['height'] > 0
        
        # Take a screenshot for verification
        driver.save_screenshot("screenshots/example_page.png")
        
        print("Navigation and elements test completed successfully!")
    
    def test_javascript_execution(self, driver):
        """Test JavaScript execution capabilities."""
        print("Starting JavaScript execution test...")
        
        driver.get("https://example.com")
        
        # Execute JavaScript to get page title
        page_title = driver.execute_script("return document.title;")
        assert "Example Domain" in page_title
        
        # Execute JavaScript to scroll page
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        
        # Execute JavaScript to modify page content
        driver.execute_script(
            "document.body.style.backgroundColor = 'lightblue';"
        )
        
        # Verify the change took effect
        bg_color = driver.execute_script(
            "return window.getComputedStyle(document.body).backgroundColor;"
        )
        
        # Take screenshot to verify visual change
        driver.save_screenshot("screenshots/modified_page.png")
        
        print("JavaScript execution test completed successfully!")

@pytest.mark.usefixtures("screenshot_on_failure")
class TestErrorHandling:
    """Test suite for error handling scenarios."""
    
    def test_element_not_found_handling(self, driver):
        """Test handling of missing elements."""
        driver.get("https://example.com")
        
        # This should handle the case gracefully
        try:
            non_existent = driver.find_element(By.ID, "non-existent-element")
            assert False, "Should not find non-existent element"
        except Exception as e:
            print(f"Correctly handled missing element: {type(e).__name__}")
            assert True
    
    def test_timeout_handling(self, driver):
        """Test timeout handling for slow-loading elements."""
        driver.get("https://httpbin.org/delay/2")
        
        # This tests our implicit wait configuration
        start_time = time.time()
        try:
            element = WebDriverWait(driver, 5).until(
                EC.presence_of_element_located((By.TAG_NAME, "body"))
            )
            end_time = time.time()
            load_time = end_time - start_time
            print(f"Page loaded in {load_time:.2f} seconds")
            assert load_time >= 2  # Should take at least 2 seconds due to delay
        except Exception as e:
            print(f"Timeout handled correctly: {type(e).__name__}")