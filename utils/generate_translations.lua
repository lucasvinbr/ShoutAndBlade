local lfs = require("lfs")

local baseDir = "/home/lucas2/dev/proyects/ShoutAndBlade/"

lfs.chdir(baseDir .. "Interface/translations/")

local filePrefix = "ShoutAndBlade_"
local baseTranslation = "ENGLISH"
local fileSuffix = ".txt"

local otherTranslations = {
    "CHINESE",
    "CZECH",
    "FRENCH",
    "GERMAN",
    "ITALIAN",
    "JAPANESE",
    "POLISH",
    "RUSSIAN",
    "SPANISH",
}

local baseFile = io.open(filePrefix .. baseTranslation .. fileSuffix, "r")

if baseFile then
    local content = baseFile:read("*a")

    print(content)

    for _, otherTrans in pairs(otherTranslations) do
        local otherFile = io.open(filePrefix .. otherTrans .. fileSuffix, "w+b")
        if otherFile then
            otherFile:write(content)
            otherFile:close()
        end
    end

    baseFile:close()
else
    print("error: base translation file not found")
end
