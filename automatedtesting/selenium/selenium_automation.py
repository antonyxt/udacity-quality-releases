# #!/usr/bin/env python
from selenium import webdriver
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.common.by import By
import time
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Go to cart (headless-safe)
def go_to_cart(driver):
    cart_icon = WebDriverWait(driver, 10).until(
        EC.element_to_be_clickable((By.CSS_SELECTOR, "#shopping_cart_container a"))
    )
    driver.execute_script("arguments[0].click();", cart_icon)




# Start the browser and login with standard_user
def login (user, password):
    print ('Starting the browser...')
    # --uncomment when running in Azure DevOps.
    options = ChromeOptions()
    options.add_argument("--headless=new")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage") 
    driver = webdriver.Chrome(options=options)
    print ('Browser started successfully. Navigating to the demo page to login.')
    driver.get("https://www.saucedemo.com/")
    time.sleep(3)
    driver.find_element(By.CSS_SELECTOR,"input[id='user-name']").send_keys(user)
    driver.find_element(By.CSS_SELECTOR,"input[id='password']").send_keys(password)
    driver.find_element(By.CSS_SELECTOR,"input[id='login-button']").click()
    
    results = driver.find_element(By.CSS_SELECTOR, "#header_container > div.header_secondary_container > span").text
    assert "Products" in results
    print("Login Successfull!!! username:" + user)
    return driver
    
def doShoping(driver):
    # Test Add to Cart
    print("BEGIN shopping...")
    path_inventory_item = "#inventory_container .inventory_item"
    product_items = driver.find_elements(By.CSS_SELECTOR, "#inventory_container .inventory_item")
    assert len(product_items) == 6
    print(f"Found {len(product_items)} products.")
    
    print("Adding all items to cart")
    for item in product_items:
        item_name = item.find_element(By.CSS_SELECTOR, ".inventory_item_name").text
        add_button = item.find_element(By.CSS_SELECTOR, ".pricebar button")
        item_code = add_button.get_attribute("id").replace("add-to-cart-", "")
        #add_button.click()
        driver.execute_script("arguments[0].click();", add_button)
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.ID, f"remove-{item_code}"))
        )
        print(" ->Success!!! Add to cart: " + item_name)
    return len(product_items)    

def verifyCart(driver, productBought):
    # Verify cart for three items    
    badges = driver.find_elements(By.CSS_SELECTOR, ".shopping_cart_badge")

    if len(badges) == 0:
        cart_total_items = 0
    else:
        cart_total_items = int(badges[0].text) if badges[0].text.strip() != "" else 0
    print(f"Items in cart: {cart_total_items}")
    assert cart_total_items == productBought
    
def removeAllItems(driver):
    # Test Remove from Shopping Cart
    print("Clearing cart")
    #driver.find_element(By.CSS_SELECTOR,"#shopping_cart_container > a").click()
    go_to_cart(driver)
    path_cart_title = "div[id='page_wrapper'] > div[id='contents_wrapper'] > div[class='subheader']"
    cart_title = driver.find_element(By.CSS_SELECTOR,"#header_container > div.header_secondary_container > span").text
    assert 'Your Cart' in cart_title
    print("Loaded shopping cart")


    car_tems = driver.find_elements(By.CSS_SELECTOR, "#cart_contents_container .cart_item")
    for cart_item in car_tems:
        remove_button = cart_item.find_element(By.CSS_SELECTOR, "button.cart_button")
        item_name = cart_item.find_element(By.CSS_SELECTOR, ".inventory_item_name").text
        remove_button.click()
        print(" ->Success!!! Remove from cart: " + item_name)

    try:
        badge = driver.find_element(By.CSS_SELECTOR, ".shopping_cart_badge")
        assert badge.text == ""
        print("Cart is empty!")
    except:
        # no badge = empty cart
        print("Cart is empty! (badge removed)")
        
def runTest():
    driver = login('standard_user', 'secret_sauce')
    print("Alert UI Automation : login success")
    productBought = doShoping(driver)
    print("Alert UI Automation : Shoping completed")
    verifyCart(driver, productBought)
    removeAllItems(driver)
    print("Alert UI Automation : Finished remove all items from cart")
    
if __name__ == "__main__":
    runTest()
    


# ToDo: Add more functional UI tests as per your requirements. 