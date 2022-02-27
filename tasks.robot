*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc.
    ${response.URL}=    Collect URL from user
    Open the robot order website    ${response.URL}
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    10x    0.5s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close the browser

*** Keywords ***
Collect URL from user
    Add text input    URL    label=URL Abfrage
    ${response}=    Run dialog
    [Return]    ${response.URL}

Close the browser
    Close Browser

Create a ZIP file of the receipts
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts${/}
    ...    ${zip_file_name}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${files}=    Create List
    ...    ${screenshot}
    ...    ${pdf}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${files}    ${pdf}
    Close Pdf

Go to order another robot
    Click Button    id:order-another

Take a screenshot of the robot
    [Arguments]    ${number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}receipts${/}screenshots${/}order_screenshot_${number}.png
    [Return]    ${OUTPUT_DIR}${/}receipts${/}screenshots${/}order_screenshot_${number}.png

Store the receipt as a PDF file
    [Arguments]    ${number}
    Wait Until Element Is Visible    id:order-completion
    ${order_results_html}=    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_results_html}    ${OUTPUT_DIR}${/}receipts${/}order_results_${number}.pdf
    [Return]    ${OUTPUT_DIR}${/}receipts${/}order_results_${number}.pdf

Open the robot order website
    [Arguments]    ${URL}
    Open Chrome Browser    ${URL}

Get orders
    ${csvUrl}=    Get Secret    credentials
    #Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${csvUrl}[URL_to_CSV]    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=TRUE
    [Return]    ${orders}

Close the annoying modal
    Click Button When Visible    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill the form
    [Arguments]    ${row}
    Select From List By Value    //*[@id="head"]    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    class:form-control    ${row}[Legs]
    Input Text    address    ${row}[Address]

Preview the robot
    Click Button    id:preview

Submit the order
    Click Button    id:order
    Wait Until Page Contains Element    id:order-completion
