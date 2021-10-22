*** Settings ***
Documentation   Template robot main suite.
Library     RPA.Browser.Selenium
Library     RPA.HTTP
Library     RPA.Tables
Library     RPA.PDF
Library     RPA.Archive
Library     RPA.FileSystem
Library     RPA.RobotLogListener
Suite Teardown    Close All Browsers


# +
*** Variables ****
${GLOBAL_WAIT_SIZE_S}=      5s
${GLOBAL_WAIT_SIZE_M}=      10s
${GLOBAL_WAIT_SIZE_L}=      30s
${GLOBAL_WAIT_SIZE_XL}=      60s

${url}=  https://robotsparebinindustries.com/
${url_download_input_file}=     https://robotsparebinindustries.com/orders.csv

${GLOBAL_RETRY_AMOUNT}=    3x
${GLOBAL_RETRY_INTERVAL}=    0.5s
# -

*** Keywords ***
Open the robot order website
    Open Chrome Browser    ${url}
    Maximize Browser Window
    Wait Until Element Is Visible    id:username    ${GLOBAL_WAIT_SIZE_XL}
    Click Element   css:LI.nav-item:nth-child(2)

*** Keywords ***
Get orders
    Download    ${url_download_input_file}      overwrite=True
    ${orders}   Read table from CSV    orders.csv   header=True    dialect=excel
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Click Button    OK
    Wait Until Element Is Visible    id:head    ${GLOBAL_WAIT_SIZE_M}

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Button    id:id-body-${row}[Body]
    Input Text    css:INPUT.form-control:nth-child(2)    ${row}[Address]
    Execute Javascript     document.getElementsByClassName('form-control')[0].setAttribute('value',${row}[Legs])

*** Keywords ***
Preview the robot
    Click Button    Preview

*** Keywords ***
Submit the order
    #Click Button    id:order
    Execute Javascript    document.getElementById('order').click()
    Wait Until Element Is Visible    id:receipt    ${GLOBAL_WAIT_SIZE_M}

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${order_number}
    Wait Until Element Is Visible    id:receipt     ${GLOBAL_WAIT_SIZE_M}
    ${html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html}    ${CURDIR}${/}output${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${order_number}
    ${screenshot}=    Screenshot     id:robot-preview-image      ${CURDIR}${/}output${/}${order_number}.png
    [Return]    ${CURDIR}${/}output${/}${order_number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${file} =     Create List    ${screenshot}
    Add files to pdf    ${file}    ${pdf}    TRUE


*** Keywords ***
Go to order another robot
    Click Button    id:order-another
    #Wait Until Element Is Visible    OK     ${GLOBAL_WAIT_SIZE_M}

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}   ${CURDIR}${/}output${/}output.zip
    ${files}=    List files in directory    ${CURDIR}${/}output${/}
    FOR    ${file}  IN  @{FILES}
        Run keyword if    ${file.name} = output    Remove file    ${file}
    END
    Remove Files
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form  ${row}
        Preview the robot
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        Log    ${pdf}
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Tasks ***
Minimal task
    Log  Done.
