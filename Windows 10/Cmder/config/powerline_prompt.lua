-- Configurations
--- plc_prompt_type is whether the displayed prompt is the full path or only the folder name
 -- Use:
 -- "full" for full path like C:\Windows\System32
local promptTypeFull = "full"
 -- "folder" for folder name only like System32
local promptTypeFolder = "folder"
 -- "smart" to switch in git repo to folder name instead of full path 
local promptTypeSmart = "smart"

 -- default is promptTypeFull
 -- Set default value if no value is already set
if not plc_prompt_type then
    plc_prompt_type = promptTypeFull
end 
if not plc_prompt_useHomeSymbol then 
	plc_prompt_useHomeSymbol = true 
end

-- Extracts only the folder name from the input Path
-- Ex: Input C:\Windows\System32 returns System32
---
local function get_folder_name(path)
	local reversePath = string.reverse(path)
	local slashIndex = string.find(reversePath, "\\")
	return string.sub(path, string.len(path) - slashIndex + 2)
end

-- * Segment object with these properties:
---- * isNeeded: sepcifies whether a segment should be added or not. For example: no Git segment is needed in a non-git folder
---- * text
---- * textColor: Use one of the color constants. Ex: colorWhite
---- * fillColor: Use one of the color constants. Ex: colorBlue
local segment = {
    isNeeded = true,
    text = "",
    textColor = colorBlack, 
    fillColor = colorWhite
}

---
-- Sets the properties of the Segment object, and prepares for a segment to be added
---
local function init()
    -- fullpath
    cwd = clink.get_cwd()

    -- show just current folder
    if plc_prompt_type == promptTypeFolder then
		cwd =  get_folder_name(cwd)
    else    
    -- show 'smart' folder name
    -- This will show the full folder path unless a Git repo is active in the folder
    -- If a Git repo is active, it will only show the folder name
    -- This helps users avoid having a super long prompt
        local git_dir = get_git_dir()
        if plc_prompt_useHomeSymbol and string.find(cwd, clink.get_env("HOME")) and git_dir ==nil then 
            -- in both smart and full if we are in home, behave like a proper command line
            cwd = string.gsub(cwd, clink.get_env("HOME"), plc_prompt_homeSymbol)
        else 
            -- either not in home or home not supported then check the smart path
            if plc_prompt_type == promptTypeSmart then
                if git_dir then
                    cwd = get_folder_name(cwd)
                    if plc_npm_gitSymbol then
                        cwd = gitSymbol.." "..cwd
                    end
                end
                -- if not git dir leave the full path
            end
        end
    end
	
	segment.text = " "..cwd.." "
end 

---
-- Uses the segment properties to add a new segment to the prompt
---
local function addAddonSegment()
    init()
    addSegment(segment.text, segment.textColor, segment.fillColor)
end

function basename(path)
    local prefix = path
    local i = path:find("[\\/:][^\\/:]*$")
    if i then
        prefix = path:sub(i + 1)
    end
    return prefix
end

function get_virtual_env(env_var)
    env_path = clink.get_env(env_var)
    if env_path then
        basen = basename(env_path)
        return basen
    end
    return false
end

function venv_prompt_filter()
    -- add in virtual env name
    local venv = get_virtual_env('VIRTUAL_ENV')
    if venv then
        clink.prompt.value = string.gsub(clink.prompt.value, "λ", "("..venv..") λ")
    end
end

-- Register this addon with Clink
clink.prompt.register_filter(addAddonSegment, 55)
clink.prompt.register_filter(venv_prompt_filter, 99)
