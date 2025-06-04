
function love.load()
    love.window.setMode(1920,1080)
    width, height = love.graphics.getDimensions()
    local shaderCode = string.format([[ 
        extern number zoom;
        extern vec2 offset;
        extern bool isJulia;
        extern vec2 julia_c;
        extern int iterCount = 1000;

        vec3 getColor(float i) {
            if (i == iterCount) return vec3(0.0);
            float t = i * 0.02;
            float angle = 6.2831 * t;
            return vec3(
                0.5 + 0.5 * sin(angle + 6.0),
                0.5 + 0.5 * sin(angle + 4.0),
                0.5 + 0.5 * sin(angle + 2.0)
            );
        }

        vec4 mandlebrot(vec2 z, vec2 c) {
            int i = 0;
            float x = z.x, y = z.y;
            for (; i < iterCount; ++i) {
                float x2 = x * x;
                float y2 = y * y;
                if (x2 + y2 > 4.0) break;
                float xy = 2.0 * x * y;
                x = x2 - y2 + c.x;
                y = xy + c.y;
            }
            vec3 color = getColor(float(i));
            return vec4(color, 1.0);
        }

        vec4 effect(vec4 color, Image tex, vec2 texCoord, vec2 screenCoord) {
            vec2 z = (screenCoord - vec2(%f, %f)) / zoom + offset;
            return isJulia ? mandlebrot(z, julia_c) : mandlebrot(z, z);
        }
    ]], width / 2, height / 2)

    shader = love.graphics.newShader(shaderCode)

    zoom = 300
    offset = { x = -0.5, y = 0.0 }
    juliaMode = false
    juliaC = { x = 0.0, y = 0.0 }
    moveSpeed = 0.005
    zoomFactor = 1.1

    dragging = false
    prevMouse = { x = 0, y = 0 }
end

function love.mousepressed(x, y, button)
    if button == 1 then
        dragging = true
        prevMouse.x = x
        prevMouse.y = y
    elseif button == 2 then
        juliaMode = false
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        dragging = false
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'r' then
        juliaMode = false
        zoom = 300
        offset = { x = -0.5, y = 0.0 }
    end
end

function love.wheelmoved(x, y)
    local mouseX, mouseY = love.mouse.getPosition()
    local worldX = (mouseX - width / 2) / zoom + offset.x
    local worldY = (mouseY - height / 2) / zoom + offset.y
    if y > 0 then
        zoom = zoom * zoomFactor
    elseif y < 0 then
        zoom = zoom / zoomFactor
    end
    offset.x = worldX - (mouseX - width / 2) / zoom
    offset.y = worldY - (mouseY - height / 2) / zoom
end

function love.update(dt)
    if love.mouse.isDown(2) then
        local x, y = love.mouse.getPosition()
        juliaMode = true
        juliaC.x = (x - width / 2) / zoom + offset.x
        juliaC.y = (y - height / 2) / zoom + offset.y
    end

    if dragging then
        local x, y = love.mouse.getPosition()
        local dx = x - prevMouse.x
        local dy = y - prevMouse.y
        offset.x = offset.x - dx / zoom
        offset.y = offset.y - dy / zoom
        prevMouse.x = x
        prevMouse.y = y
    end
end

function love.draw()
    shader:send("zoom", zoom)
    shader:send("offset", { offset.x, offset.y })
    shader:send("isJulia", juliaMode)
    shader:send("julia_c", { juliaC.x, juliaC.y })
    love.graphics.setShader(shader)
    love.graphics.rectangle("fill", 0, 0, width, height)
    love.graphics.setShader()
end
