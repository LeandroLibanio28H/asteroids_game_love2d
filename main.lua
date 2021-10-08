--[[
    Asteroids game clone.
    LibanioL 2021
]]


-- Game entry point
function love.load()
    local ecs = require("lib.ecs.ecs")
    local vector2 = require("src.vector.vector2")

    World = ecs.newWorld()

    local playerShip = {
        image = love.graphics.newImage("res/playership/textures/ship.png"),
        transform = {
            position = vector2:new(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2),
            scale = vector2:new(1, 1),
            rotation = 0
        },
        movement = {
            velocity = vector2.new(0, 0),
            rotation = 0,
            moveSpeed = 100,
            rotationSpeed = math.rad(90)
        },
        playerInput = {
            up = false,
            left = false,
            right = false,
            down = false
        }
    }

    -- Render System
    local renderFilter = ecs.newFilter()
    renderFilter:addExpresion(ecs.newRequireAllFilterExpression("image", "transform"))
    local renderSystem = ecs.newRenderSystem(renderFilter, function (e, id)
        love.graphics.draw(
            e.image,
            e.transform.position.x,
            e.transform.position.y,
            e.transform.rotation,
            e.transform.scale.x,
            e.transform.scale.y,
            e.image:getWidth() / 2,
            e.image:getHeight() / 2
        )
    end)

    -- Entity Movement System
    local movementFilter = ecs.newFilter()
    movementFilter:addExpresion(ecs.newRequireAllFilterExpression("movement", "transform"))
    local movementSystem = ecs.newProcessingSystem(movementFilter, function (e, id, dt)
        if e.playerInput then
            e.movement.rotation = 0
            e.movement.velocity = vector2:new()
            if e.playerInput.up then
                e.movement.velocity.y = e.movement.velocity.y -1
            end
            if e.playerInput.down then
                e.movement.velocity.y = e.movement.velocity.y + 0.5
            end

            e.movement.velocity:rotate(e.transform.rotation)

            if e.playerInput.left then
                e.movement.rotation = e.movement.rotation - 1
            end
            if e.playerInput.right then
                e.movement.rotation = e.movement.rotation + 1
            end
        end

        e.transform.position.x = e.transform.position.x + e.movement.velocity.x * dt * e.movement.moveSpeed
        e.transform.position.y = e.transform.position.y + e.movement.velocity.y * dt * e.movement.moveSpeed
        e.transform.rotation = e.transform.rotation + e.movement.rotation * dt * e.movement.rotationSpeed
    end)

    -- Player Input System
    local playerInputFilter = ecs.newFilter()
    playerInputFilter:addExpresion(ecs.newRequireAllFilterExpression("movement", "playerInput"))
    local playerInputSystem = ecs.newKeyboardSystem(playerInputFilter, function (e, id, k, s, r, p)
        for key, _ in pairs(e.playerInput) do
            if key == k then
                e.playerInput[key] = p
            end
            if k == 'x' then
                print("aqui foi")
                World:removeEntity(id)
            end
        end
    end)

    World:addRenderSystem(renderSystem)
    World:addProcessingSystem(movementSystem)
    World:addKeyboardSystem(playerInputSystem)

    World:addEntity(playerShip)
end


-- Game loop
function love.update(dt)
    World:updateProcessSystems(dt)
end


-- Game rendering
function love.draw()
    love.graphics.print(love.timer.getFPS())
    World:updateRenderSystems()
end


-- Game keyboard callbacks
-- Key pressed
function love.keypressed(key, scan, isrepeat)
    if key == "escape" then love.event.quit() end
    World:updateKeyboardSystems(key, scan, isrepeat, true)
end

-- Key released
function love.keyreleased(key, scan)
    World:updateKeyboardSystems(key, scan, false, false)
end