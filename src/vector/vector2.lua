local vector = {}


function vector:new(vx, vy)
    -- Vector table
    local vector2 = {
        x = 0.0,
        y = 0.0
    }

    if vx then vector2.x = vx end
    if vy then vector2.y = vy end


    -- vector normalize funcion
    function vector2:normalize()
       self.x = self.x / self:length()
       self.y = self.y / self:length()
    end

    -- vector length
    function vector2:length()
        return math.sqrt(self.x * self.x + self.y * self.y)
    end

    -- vector rotate
    function vector2:rotate(r)
        local rx = self.x * math.cos(r) - self.y * math.sin(r)
        local ry = self.x * math.sin(r) + self.y * math.cos(r)

        self.x = rx
        self.y = ry
    end


    return vector2
end

return vector