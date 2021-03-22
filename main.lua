-- By Gauthier G.
-- This plugin allow to create group and layout view for JDC1 in SpixPro Mode (62 channel).
-- v1.1
-- Mars 2021
-- offset entre les JDC dans le layout view
layoutOffsetX = 8 -- Distance entre 2 instance main en X
layoutOffsetY = 7 -- Distance entre 2 instance main en Y

-- Ne pas toucher au code en dessous

local xmlFileContent =
    '<?xml version="1.0" encoding="utf-8"?><MA xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.malighting.de/grandma2/xml/MA" xsi:schemaLocation="http://schemas.malighting.de/grandma2/xml/MA http://schemas.malighting.de/grandma2/xml/3.9.0/MA.xsd" major_vers="1" minor_vers="0" stream_vers="0"><Info datetime="2020-11-14T01:13:58" showfile="plugin code" /><Group index="1" name="JDC"><Subfixtures>'

local function erreur(detail)
    gma.gui.msgbox("JDCs instances plugin ERROR", detail)
    gma.feedback("--- JDCs instances plugin ERROR ---")
end

local function feedback(detail)
    gma.feedback("JDCs instances plugin : " .. detail)
end

-- Select main instance of fixture
local function mainInstanceSelect(fixture)
    gma.cmd("Fixture " .. fixture .. ".1")
end

-- Select RGB Panel of fixture
local function panelInstanceSelect(fixture)
    gma.cmd("Fixture " .. fixture .. ".2 Thru " .. fixture .. ".13")
end

-- Select Strobe Cell of fixture
local function ledStrobeCellSelect(fixture)
    gma.cmd("Fixture " .. fixture .. ".14 Thru " .. fixture .. ".25")
end

-- Store and label group
local function storeGroup(groupID, label)
    gma.cmd("Store Group " .. groupID)
    gma.cmd("Label Group " .. groupID .. " " .. label)
end

-- Declare fixture in layout xml
local function defFixtInLayout(fixture)
    for x = 1, 25, 1 do
        xmlFileContent = xmlFileContent .. '<Subfixture fix_id="' .. fixture .. '" sub_index="' .. x .. '" />'
    end
end

-- Setup fixture in layout xml
local function setupFixtInLayout(fixture, offset_x, offset_y)
    for x = 1, 25, 1 do
        if (x == 1) then -- if main instance put on top
            pos_x = 0 + offset_x
            pos_y = 0 + offset_y
            xmlFileContent = xmlFileContent .. '<LayoutSubFix center_x="' .. pos_x .. '" center_y="' .. pos_y ..
                                 '" size_h="1" size_w="1" background_color="00000000" icon="None" show_id="1" show_type="1" function_type="Filled" select_group="1"><image /><Subfixture fix_id="' ..
                                 fixture .. '" sub_index="' .. x .. '" /></LayoutSubFix>'
        end
        if (x >= 2 and x <= 7) then -- if rgb panel raw 1 arrange them
            pos_x = x - 2 + offset_x
            pos_y = 2 + offset_y
            xmlFileContent = xmlFileContent .. '<LayoutSubFix center_x="' .. pos_x .. '" center_y="' .. pos_y ..
                                 '" size_h="1" size_w="1" background_color="00000000" icon="None" show_id="1" show_type="1" function_type="Filled" select_group="1"><image /><Subfixture fix_id="' ..
                                 fixture .. '" sub_index="' .. x .. '" /></LayoutSubFix>'
        end
        if (x >= 8 and x <= 13) then -- if rgb panel raw 2 arrange them
            pos_x = x - 8 + offset_x
            pos_y = 4 + offset_y
            xmlFileContent = xmlFileContent .. '<LayoutSubFix center_x="' .. pos_x .. '" center_y="' .. pos_y ..
                                 '" size_h="1" size_w="1" background_color="00000000" icon="None" show_id="1" show_type="1" function_type="Filled" select_group="1"><image /><Subfixture fix_id="' ..
                                 fixture .. '" sub_index="' .. x .. '" /></LayoutSubFix>'
        end
        if (x >= 14 and x <= 25) then -- if strobe cell arrange them
            pos_x = (x - 14.5) / 2 + offset_x
            pos_y = 3 + offset_y
            xmlFileContent = xmlFileContent .. '<LayoutSubFix center_x="' .. pos_x .. '" center_y="' .. pos_y ..
                                 '" size_h="1" size_w="0.5" background_color="00000000" icon="None" show_id="1" show_type="1" function_type="Filled" select_group="1"><image /><Subfixture fix_id="' ..
                                 fixture .. '" sub_index="' .. x .. '" /></LayoutSubFix>'
        end
    end
end

local function start()
    gma.feedback("--- JDCs instances group creator started ---")
    local classType = tostring(gma.textinput("group or fixture", "fixture"))
    if classType == "fixture" then      -- Si mode fixture
        local startID = tonumber(gma.textinput("Start Fixture ID", ""))
        local endID = tonumber(gma.textinput("End Fixture ID", ""))
        local startGroupID = tonumber(gma.textinput("Start group ID (3 available group)", ""))
        local layoutViewID = tonumber(gma.textinput("Layout ViewID ", ""))
        if (startID > endID) then -- test pour remettre dans l'ordre les 2 nombres
            local bridge = endID
            endID = startID
            startID = bridge
        end

    elseif classType == "group" then    -- Si mode group - Par florian Anaya
        groupID = tonumber(gma.textinput("Group ID", ""))
        gma.cmd("SelectDrive 1")
        local fileName = 'tempfile.xml'
        local filePath = gma.show.getvar('PATH') .. '/importexport/ .. fileName'
        gma.cmd("Export Group " .. groupID .. " \"" .. fileName .. "\"")

        local file = io.open(filePath, "r")
        local fileContent = file:read('*a')
        file:close()

        os.remove(filePath)

        for match in fileContent:gmatch('<Subfixture (.-) />') do
            feedback(match)
        end

    else
        erreur("Incompatible entry class !")
    end

    if (gma.gui.confirm("Confirm", "Confirm JDCs instances group and layout create for Fixture " .. startID .. " to " ..
        endID .. " ?")) then
        feedback("Create group and layout confirm for JDC1 Fixture " .. startID .. " to " .. endID)

        progress_bar = gma.gui.progress.start("JDCs Instance Plugin")
        gma.gui.progress.setrange(progress_bar, 0, 6)

        -- Main Instance
        for x = startID, endID, 1 do
            mainInstanceSelect(x)
        end
        storeGroup(startGroupID, "JDC_Main")
        gma.cmd("ClearAll")
        gma.gui.progress.set(progress_bar, 1)

        -- RGB Panel instances
        for x = startID, endID, 1 do
            panelInstanceSelect(x)
        end
        storeGroup(startGroupID + 1, "JDC_LED_Panel")
        gma.cmd("ClearAll")
        gma.gui.progress.set(progress_bar, 2)

        -- Strobe cell instances
        for x = startID, endID, 1 do
            ledStrobeCellSelect(x)
        end
        storeGroup(startGroupID + 2, "JDC_LED_Strobe")
        gma.cmd("ClearAll")
        gma.gui.progress.set(progress_bar, 3)

        -- Declare fixtures in layout xml
        for x = startID, endID, 1 do
            defFixtInLayout(x)
            feedback("Def fixture " .. x .. " in layout xml")
        end
        gma.gui.progress.set(progress_bar, 4)

        -- Add mid content in xml
        xmlFileContent = xmlFileContent ..
                             "</Subfixtures><LayoutData index='0' marker_visible='true' background_color='000000' visible_grid_h='1' visible_grid_w='1' snap_grid_h='0.5' snap_grid_w='0.5' default_gauge='Filled &amp; Symbol' subfixture_view_mode='DMX Layer'><SubFixtures>"

        -- Setup fixtures in layout xml
        local countFixture = 0
        local countFixtureY = 0
        for x = startID, endID, 1 do
            setupFixtInLayout(x, countFixture * layoutOffsetX, countFixtureY * layoutOffsetY)
            feedback("Setup fixture " .. x .. " in layout xml")
            countFixture = countFixture + 1
            if (countFixture >= layoutOffsetX) then
                countFixture = 0
                countFixtureY = countFixtureY + 1
            end
        end
        gma.gui.progress.set(progress_bar, 5)

        -- Finish xml
        xmlFileContent = xmlFileContent .. "</SubFixtures></LayoutData></Group></MA>"

        -- Store xml variable in xml file (Thanks to Florian ANAYA)
        local fileName = "layouttemp.xml"
        local filePath = gma.show.getvar('PATH') .. '/importexport/' .. fileName
        local file = io.open(filePath, "w")
        file:write(xmlFileContent)
        file:close()
        feedback("XML File created")

        -- Import xml in layout
        gma.cmd('Import "' .. fileName .. '" Layout ' .. layoutViewID)
        feedback("Layout imported")
        gma.gui.progress.set(progress_bar, 6)

        gma.sleep(0.5)
        gma.gui.progress.stop(progress_bar)
        gma.feedback("--- JDCs instances group creator finished ---")
    else
        feedback("Operation canceled")
        gma.feedback("--- JDCs instances group creator finished ---")
    end
end

return start
