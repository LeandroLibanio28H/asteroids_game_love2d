local ecs = {}

-- ###########################################################################
-- Entity Component System module WIP
-- Lots of improvements to make
-- TODO: Refactoring and working on performance (Adding entities and calling updates)


-- ###########################################################################
-- World


-- Creates a new world
-- Worlds are entity, component and system containers
function ecs.newWorld()
    local world = {
        entities = {}, -- Entities

        processSystems = {}, -- Process systems (love.update)
        renderSystems = {}, -- Render systems (love.draw)
        keyBoardSystems = {} -- Keyboard systems (love.keypressed, love.keyreleased)
    }

    -- Update the processing systems (This should be called in love.update callback)
    -- Params:
    --  dt: deltatime
    function world:updateProcessSystems(dt)
        for _, v in ipairs(self.processSystems) do
            if v.update then v:update(self, dt) end
        end
    end

    -- Update the render systems (This should be called in love.draw callback)
    function world:updateRenderSystems()
        for _, v in ipairs(self.renderSystems) do
            if v.update then v:update(self) end
        end
    end

    -- Update the keyboard systems (This should be called in love.keypressed and love.keyreleased callbacks)
    -- Params:
    --  k: key pressed
    --  s: scancode
    --  r: is repeat
    --  p: pressed (true or false)
    function world:updateKeyboardSystems(k, s, r, p)
        for _, v in ipairs(self.keyBoardSystems) do
            if v.update then v:update(self, k, s, r, p) end
        end
    end


    -- Add Entity to the world
    -- Entities are only tables with data (components)
    function world:addEntity(entity)
        for k, v in ipairs(self.processSystems) do
            v:_evaluate(entity, k)
        end
        for k, v in ipairs(self.renderSystems) do
            v:_evaluate(entity, k)
        end
        for k, v in ipairs(self.keyBoardSystems) do
            v:_evaluate(entity, k)
        end

        table.insert(self.entities, entity)
        return #self.entities
    end


    -- Remove entity
    function world:removeEntity(id)
        self.entities[id] = false
    end


    -- Add a processing system to the world
    function world:addProcessingSystem(system)
        if #self.entities > 0 then
            error 'Unable to create systems at runtime!'
        else
            table.insert(self.processSystems, system)
        end
    end

    -- Add a render system to the world
    function world:addRenderSystem(system)
        if #self.entities > 0 then
            error 'Unable to create systems at runtime!'
        else
            table.insert(self.renderSystems, system)
        end
    end

    -- Add a Keyboard system to the world
    function world:addKeyboardSystem(system)
        if #self.entities > 0 then
            error 'Unable to create systems when there are entities in the world!'
        else
            table.insert(self.keyBoardSystems, system)
        end
    end

    return world
end


-- ############################################################################
-- Systems
-- TODO: Refactor and remove duplicity


-- Helper system
local function _newSystem()
    local system = {
        filter = {},
        registeredEntities = {},
    }
    function system:_evaluate(e, id)
        local result = true
        for i = 1, #self.filter.expressions do
            result = self.filter.expressions[i]:fn(e)
        end

        if result then
            table.insert(self.registeredEntities, id, id)
        end
    end

    return system
end

-- Creates a new processing system
function ecs.newProcessingSystem(filter, fn)
    local system = _newSystem()
    system.filter = filter
    system.run = fn

    function system:update(world, dt)
        for id, e in pairs(self.registeredEntities) do
            if world.entities[id] then
                self.run(world.entities[e], id, dt)
            end
        end
    end

    return system
end

-- Creates a new render system
function ecs.newRenderSystem(filter, fn)
    local system = _newSystem()
    system.filter = filter
    system.run = fn

    function system:update(world)
        for id, e in pairs(self.registeredEntities) do
            if world.entities[id] then
                self.run(world.entities[e], id)
            end
        end
    end

    return system
end

-- Creates a new Keyboard system
function ecs.newKeyboardSystem(filter, fn)
    local system = _newSystem()
    system.filter = filter
    system.run = fn

    function system:update(world, k, s, r, p)
        for id, e in pairs(self.registeredEntities) do
            if world.entities[id] then
                self.run(world.entities[e], id, k, s, r, p)
            end
        end
    end

    return system
end


-- ############################################################################
-- Filters

-- Creates a new filter for systems
function ecs.newFilter()
    local filter = {
        expressions = {},

        -- Add a FilterExpression to the filter
        addExpresion = function(self, expression)
            table.insert(self.expressions, expression)
        end
    }
    return filter
end


-- ############################################################################
-- Expressions
-- TODO: Refactor and remove duplicity

-- Creates a new filter expression.
-- RequireAllFilterExpressions will select only entities with all listed components
function ecs.newRequireAllFilterExpression(...)
    local expression = {
        items = {},
        fn = nil
    }
    for i = 1, select('#', ...) do
        local item = select(i, ...)
        if (type(item) == 'string') then
            table.insert(expression.items, item)
        else
            error('Filters must always be strings!')
        end
    end
    function expression:fn(e)
        for i = 1, #self.items do
            local item = self.items[i]
            if not e[item] then
                return false
            end
        end
        return true
    end

    return expression
end

-- Creates a new filter expression.
-- RequireAnyFilterExpression will select only entities with at least one listed component
function ecs.newRequireAnyFilterExpression(...)
    local expression = {
        items = {},
        fn = nil
    }
    for i = 1, select('#', ...) do
        local item = select(i, ...)
        if (type(item) == 'string') then
            table.insert(expression.items, item)
        else
            error('Filters must always be strings!')
        end
    end
    function expression:fn(e)
        for i = 1, #self.items do
            local item = self.items[i]
            if e[item] then
                return true
            end
        end
        return false
    end
end

-- Creates a new filter expression.
-- RejectAllFilterExpression will select only entities with none of listed components
function ecs.newRejectAllFilterExpression(...)
    local expression = {
        items = {},
        fn = nil
    }
    for i = 1, select('#', ...) do
        local item = select(i, ...)
        if (type(item) == 'string') then
            table.insert(expression.items, item)
        else
            error('Filters must always be strings!')
        end
    end
    function expression:fn(e)
        for i = 1, #self.items do
            local item = self.items[i]
            if e[item] then
                return false
            end
        end
        return true
    end
end

-- Creates a new filter expression.
-- RejectAnyFilterExpression will select only entities without at least one of listed component
function ecs.newRejectAnyFilterExpression(...)
    local expression = {
        items = {},
        fn = nil
    }
    for i = 1, select('#', ...) do
        local item = select(i, ...)
        if (type(item) == 'string') then
            table.insert(expression.items, item)
        else
            error('Filters must always be strings!')
        end
    end
    function expression:fn(e)
        for i = 1, #self.items do
            local item = self.items[i]
            if not e[item] then
                return true
            end
        end
        return false
    end
end


-- ############################################################################
return ecs