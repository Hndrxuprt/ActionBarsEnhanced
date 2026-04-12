local AddonName, Addon = ...

function Addon:ApplyActionBarsCenteredGrid(self, layoutChildren, stride, padding)
    if #layoutChildren == 0 then return end

    stride = math.min(stride, #layoutChildren)

    local firstChild = layoutChildren[1]
    local width = firstChild:GetWidth()
    local height = firstChild:GetHeight()

    if width == 0 or height == 0 then
        width, height = 36, 36
    end

    local spacing = padding
    local addButtonsToRight = self.addButtonsToRight
    local addButtonsToTop = self.addButtonsToTop

    local anchorPoint
    if addButtonsToTop then
        anchorPoint = addButtonsToRight and "BOTTOMLEFT" or "BOTTOMRIGHT"
    else
        anchorPoint = addButtonsToRight and "TOPLEFT" or "TOPRIGHT"
    end

    if self.isHorizontal then
        local itemStep = width + spacing
        local rowStep = height + spacing
        local fullRowWidth = (stride * width) + ((stride - 1) * spacing)
        local numRows = math.ceil(#layoutChildren / stride)

        for rowIndex = 0, numRows - 1 do
            local rowStart = rowIndex * stride + 1
            local rowEnd = math.min(rowStart + stride - 1, #layoutChildren)
            local itemCount = rowEnd - rowStart + 1

            local actualRowWidth = (itemCount * width) + ((itemCount - 1) * spacing)
            local xOffsetForRow = (fullRowWidth - actualRowWidth) / 2
            
            local yOffset = rowIndex * rowStep

            for i = rowStart, rowEnd do
                local child = layoutChildren[i]
                local itemIndex = i - rowStart
                local xOffset = xOffsetForRow + itemIndex * itemStep

                local finalX = addButtonsToRight and xOffset or -xOffset
                
                local finalY
                if addButtonsToTop then
                    finalY = yOffset
                else
                    finalY = -yOffset
                end
                child:ClearAllPoints()
                child:SetPoint(anchorPoint, self, anchorPoint, finalX, finalY)
            end
        end

        local totalWidth = (stride * width) + ((stride - 1) * spacing)
        local totalHeight = (numRows * height) + ((numRows - 1) * spacing)
        self:SetSize(totalWidth, totalHeight)
        
    else
        local itemStep = height + spacing
        local colStep = width + spacing
        local maxRows = stride
        local numCols = math.ceil(#layoutChildren / maxRows)
        local fullColHeight = (maxRows * height) + ((maxRows - 1) * spacing)

        for colIndex = 0, numCols - 1 do
            local colStart = colIndex * maxRows + 1
            local colEnd = math.min(colStart + maxRows - 1, #layoutChildren)
            local itemCount = colEnd - colStart + 1

            local actualColHeight = (itemCount * height) + ((itemCount - 1) * spacing)
            local yOffsetForCol = (fullColHeight - actualColHeight) / 2
            local xOffset = colIndex * colStep

            for i = colStart, colEnd do
                local child = layoutChildren[i]
                local itemIndex = i - colStart
                local yOffset = yOffsetForCol + itemIndex * itemStep

                local finalX = addButtonsToRight and xOffset or -xOffset
                local finalY = addButtonsToTop and yOffset or -yOffset

                child:ClearAllPoints()
                child:SetPoint(anchorPoint, self, anchorPoint, finalX, finalY)
            end
        end

        local totalWidth = (numCols * width) + ((numCols - 1) * spacing)
        local totalHeight = (maxRows * height) + ((maxRows - 1) * spacing)
        self:SetSize(totalWidth, totalHeight)
    end
end

local function HideInactiveChildren(layoutChildren, keepEmpty)
    if #layoutChildren == 0 then return end
    
    local visible = {}
    for _, frame in ipairs(layoutChildren) do
        if frame.__isActive ~= nil then
            if frame.__isActive or frame.__isEditing or EditModeManagerFrame:IsEditModeActive() or CooldownViewerSettings:IsVisible() then
                frame:Show()
                table.insert(visible, frame)
            elseif keepEmpty then
                frame:Hide()
                table.insert(visible, frame)
            else
                frame:Hide()
            end
        else
            if (frame:IsVisible() or frame.__shouldBeVisible) or frame.__isEditing or EditModeManagerFrame:IsEditModeActive() or CooldownViewerSettings:IsVisible() then
                if not frame:IsVisible() then
                    frame:Show()
                end
                table.insert(visible, frame)
            else
                if keepEmpty then
                    frame:Hide()
                    table.insert(visible, frame)
                else
                    frame:Hide()
                end
            end
        end
    end

    return visible
end

function Addon:ApplyStandardGridLayout(self, layoutChildren, stride, padding)

    if not self or not layoutChildren then
        return
    end

    if #layoutChildren == 0 then return end

    local keepEmpty = self.keepEmpty
    local visibleChildren = HideInactiveChildren(layoutChildren, keepEmpty)

    if self.__wasVisibleChildren == #visibleChildren then
        return
    end

    self.__wasVisibleChildren = #visibleChildren

    local layoutFramesGoingRight
    if self.__layoutFramesGoingRight ~= nil then
        layoutFramesGoingRight = self.__layoutFramesGoingRight == 1
    else
        layoutFramesGoingRight = self.layoutFramesGoingRight
    end
    local layoutFramesGoingUp
    if self.__layoutFramesGoingUp ~= nil then
        layoutFramesGoingUp = self.__layoutFramesGoingUp == 1
    else
        layoutFramesGoingUp = self.layoutFramesGoingUp
    end

    local xMultiplier = layoutFramesGoingRight and 1 or -1
    local yMultiplier = layoutFramesGoingUp and 1 or -1

    local layout
    if self.isHorizontal then
        layout = GridLayoutUtil.CreateStandardGridLayout(stride, padding, padding, xMultiplier, yMultiplier)
    else
        layout = GridLayoutUtil.CreateVerticalGridLayout(stride, padding, padding, xMultiplier, yMultiplier)
    end

    local anchorPoint
    if layoutFramesGoingUp then
        anchorPoint = layoutFramesGoingRight and "BOTTOMLEFT" or "BOTTOMRIGHT"
    else
        anchorPoint = layoutFramesGoingRight and "TOPLEFT" or "TOPRIGHT"
    end
    GridLayoutUtil.ApplyGridLayout(visibleChildren, AnchorUtil.CreateAnchor(anchorPoint, self, anchorPoint), layout) 
end

function Addon:ApplyCenteredGridLayout(self, layoutChildren, stride, padding)
    if not self or not layoutChildren then
        return
    end

    if #layoutChildren == 0 then return end

    local keepEmpty = false -- Centered grid always filter empty
    local visibleChildren = HideInactiveChildren(layoutChildren, keepEmpty)

    if self.__wasVisibleChildren == #visibleChildren then
        return
    end

    self.__wasVisibleChildren = #visibleChildren

    if #visibleChildren == 0 then return end

    stride = math.min(stride, #visibleChildren)

    local firstChild = visibleChildren[1]
    local width = firstChild:GetWidth()
    local height = firstChild:GetHeight()

    if width == 0 or height == 0 then
        width, height = 36, 36
    end

    local spacing = padding
    local isHorizontal = self.isHorizontal
    local layoutFramesGoingRight

    if self.__layoutFramesGoingRight ~= nil then
        layoutFramesGoingRight = self.__layoutFramesGoingRight == 1
    else
        layoutFramesGoingRight = self.layoutFramesGoingRight
    end
    local layoutFramesGoingUp
    if self.__layoutFramesGoingUp ~= nil then
        layoutFramesGoingUp = self.__layoutFramesGoingUp == 1
    else
        layoutFramesGoingUp = self.layoutFramesGoingUp
    end

    local anchorPoint

    if isHorizontal then
        anchorPoint = layoutFramesGoingUp and "BOTTOM" or "TOP"
    else
        anchorPoint = layoutFramesGoingRight and "LEFT" or "RIGHT"
    end

    if isHorizontal then
        local itemStep = width + spacing
        local rowStep = height + spacing
        local numRows = math.ceil(#visibleChildren / stride)

        for rowIndex = 0, numRows - 1 do
            local rowStart = rowIndex * stride + 1
            local rowEnd = math.min(rowStart + stride - 1, #visibleChildren)
            local itemCount = rowEnd - rowStart + 1

            local halfWidth = (itemCount - 1) * itemStep / 2
            local startX = layoutFramesGoingRight and -halfWidth or halfWidth
            local stepX = layoutFramesGoingRight and itemStep or -itemStep

            local y = rowIndex * rowStep
            if not layoutFramesGoingUp then
                y = -y
            end

            for i = rowStart, rowEnd do
                local child = visibleChildren[i]
                local itemIndex = i - rowStart
                local x = startX + itemIndex * stepX
                child:ClearAllPoints()
                child:SetPoint(anchorPoint, self, anchorPoint, x, y)
            end
        end
    else
        local itemStep = height + spacing
        local colStep = width + spacing
        local numCols = math.ceil(#visibleChildren / stride)

        for colIndex = 0, numCols - 1 do
            local colStart = colIndex * stride + 1
            local colEnd = math.min(colStart + stride - 1, #visibleChildren)
            local itemCount = colEnd - colStart + 1

            local halfHeight = (itemCount - 1) * itemStep / 2
            local startY = layoutFramesGoingUp and -halfHeight or halfHeight
            local stepY = layoutFramesGoingUp and itemStep or -itemStep

            local x = colIndex * colStep
            x = layoutFramesGoingRight and x or -x

            for i = colStart, colEnd do
                local child = visibleChildren[i]
                local itemIndex = i - colStart
                local y = startY + itemIndex * stepY
                child:ClearAllPoints()
                child:SetPoint(anchorPoint, self, anchorPoint, x, y)
            end
        end
    end
end

function Addon:ResizeLayout(frame, visibleChildren)
    if not frame then return end

    local layoutChildren = visibleChildren or frame:GetLayoutChildren()

    frame:SetSize(1,1)

    if #layoutChildren == 0 then
        frame:SetSize(40,40)
        return
    end

    local width = layoutChildren[1]:GetWidth()
    local height = layoutChildren[1]:GetHeight()

    if width == 0 or height == 0 then
        width, height = 40, 40
    end

    local numActive = #layoutChildren
    local isHorizontal = frame.isHorizontal
    local padding = frame.__padding
    local stride = frame.stride

    stride = math.min(stride, numActive)

    local numRows = math.ceil(numActive / stride)
    local totalWidth
    local totalHeight
    if isHorizontal then
        totalWidth = (stride * width) + ((stride - 1) * padding)
        totalHeight = (numRows * height) + ((numRows - 1) * padding)
    else
        totalWidth = (numRows * width) + ((numRows - 1) * padding)
        totalHeight = (stride * height) + ((stride - 1) * padding)
    end

    frame:SetSize(totalWidth, totalHeight)
end