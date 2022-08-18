*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.Excel.Application
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Desktop
Library             RPA.Tables
Library             RPA.Windows
Library             RPA.Dialogs
Library             RPA.PDF
Library             RPA.Robocorp.Process
Library             RPA.FTP
Library             RPA.Archive
Library             RPA.FileSystem
Library             RequestsLibrary
Library             RPA.Windows
Library             RPA.Robocorp.Vault
Library             Process
Library             RPA.Outlook.Application
Library             RPA.Tasks


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the RobotSpareBin website
    @{orders}=    Get orders
    FOR    ${single_order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${single_order}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${single_order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${single_order}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Close everything


*** Keywords ***
Open the RobotSpareBin website
    ${browser}=    Get Secret    rsbwebsite
    Open Available Browser    ${browser}[rsbwebsite]

Get orders
    Add heading    Enter CSV File Name
    Add text input    orders
    ${response}=    Run dialog
    Open File    ${CURDIR}${/}${response.orders}
    @{orders}=    Read table from CSV    ${response.orders}    header=True
    FOR    ${order}    IN    @{orders}
        Log    ${order}
    END
    RETURN    @{orders}

Close the annoying modal
    Click Button    OK

Fill the form
    [Arguments]    ${single_order}
    Select From List By Value    head    ${single_order}[Head]
    Select Radio Button    body    ${single_order}[Body]
    Input Text    css:.form-control    ${single_order}[Legs]
    Input Text    address    ${single_order}[Address]

Fill the form using Data
    [Arguments]    @{orders}
    Open File    @{orders}
    ${single_order}=    Read table from CSV    @{orders}    header=True
    FOR    ${single_order}    IN    @{orders}
        Log    ${single_order}
        Fill the form    ${single_order}
    END

Preview the robot
    Click Button    Preview

Submit the order
    TRY
        Click Button    order
        Wait Until Element Is Visible    receipt
    EXCEPT
        Wait Until Keyword Succeeds    3x    2 sec    Click Button    Preview
        Wait Until Element Is Not Visible    css:.alert-danger
        Wait Until Keyword Succeeds    3x    2 sec    Click Button    order
        Wait Until Element Is Visible    receipt
    END
    #Wait Until Keyword Succeeds    2x    20 sec    Submit the order

Store the receipt as a PDF file
    [Arguments]    ${order}
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${order}.pdf
    RETURN    ${OUTPUT_DIR}${/}${order}.pdf

Take a screenshot of the robot
    [Arguments]    ${order}
    RPA.Browser.Selenium.Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}${order}_Picture.png
    RETURN    ${OUTPUT_DIR}${/}${order}_Picture.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Open Pdf    ${pdf}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf}
    Close Pdf

Go to order another robot
    Wait Until Element Is Visible    order-another
    Click Button    order-another

Create a ZIP file of the receipts
    ${robot_receipts}=    Set Variable    ${OUTPUT_DIR}/robot_receipts.zip
    Archive Folder With Zip    ${OUTPUT_DIR}    ${robot_receipts}

Close everything
    Close All Applications
    Close Browser
    Terminate All Processes
