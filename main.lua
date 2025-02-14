-- main.lua

-- Requer as bibliotecas
local lume = require "lume"
local suit = require "suit"

-- Variáveis globais
local world
local ground, ceiling
local boxes = {} -- Lista para armazenar as molas criadas
local mouseJoint -- O Joint que permite mover a mola com o mouse
local selectedObject
local currentboxID = 0 -- ID único para cada mola criada
local destroyBox = {x = love.graphics.getWidth() - 120, y = 10, w = 100, h = 70} -- Caixa para destruir molas
-- Variáveis globais para as dimensões da mola
local boxWidth = 64
local boxHeight = 64
local springs = {}  -- Lista de molas
local lastMouseX, lastMouseY = love.mouse.getPosition()
local showTable = false
local selectedSpring = nil


local largura = love.graphics.getWidth() +565
local altura = 20
local groundX = largura / 2 + 35
local groundY = love.graphics.getHeight() +350
local ceilingX = largura / 2 + 35
local ceilingY = altura / 2 +45

local screenWidth, screenHeight = love.window.getDesktopDimensions()
        -- Define as áreas para a simulação e os botões
local simAreaWidth = screenWidth * 0.75 -- 75% da tela para a simulação
local uiAreaWidth = screenWidth * 0.25  -- 25% da tela para os botões


-- Variáveis para os valores das caixas (em metros)
local inputWidth = { text = "1" }    -- 1 metro de largura
local inputHeight = { text = "1" }   -- 1 metro de altura
local inputMass = { text = "1.0" }    -- Massa em kg (ou o que você definir)
local inputSpringK = { text = "10.0" }
-- Limite máximo de molas por ponto (ex.: 1)
local MAX_OCCUPANCY = 1
-- Tabela para registrar quantas molas estão conectadas em cada ponto do teto
local ceilingSnapOccupancy = {}

local showForceInfo = false
local serieForce = 0
local parallelForce = 0
local totalK =0
local connectedSprings = {}



function love.load()


        -- Define a janela em um tamanho grande, mas sem fullscreen
    love.window.setMode(screenWidth * 0.9, screenHeight * 0.9, {
        fullscreen = false,  -- Mantém em modo janela
        borderless = false,  -- Garante que tenha bordas
        resizable = true     -- Permite redimensionamento manual
    })


    
    love.physics.setMeter(64) -- Define 1 metro como 64 pixels
    -- Configura o mundo físico
    
    world = love.physics.newWorld(0, 9.81 * 64, true) -- Gravidade padrão



    -- Atualiza o tamanho do chão e do teto com a nova largura
    ground = love.physics.newBody(world, groundX, groundY, "static")
    local groundShape = love.physics.newRectangleShape(largura, altura)
    love.physics.newFixture(ground, groundShape)

    ceiling = love.physics.newBody(world, ceilingX, ceilingY, "static")
    local ceilingShape = love.physics.newRectangleShape(largura, altura)
    love.physics.newFixture(ceiling, ceilingShape)
    -- Inicializa o mouseJoint como nulo
    mouseJoint = nil
    
    -- Initialize mouse positions for tracking
    local mx, my = love.mouse.getPosition()
    lastMouseX, lastMouseY = mx, my
end

function love.textinput(t)
    suit.textinput(t)
end

function love.keypressed(key, scancode, isrepeat)
    suit.keypressed(key, scancode, isrepeat)
end


function love.update(dt)

    -- Atualiza o mundo físico
    world:update(dt)

    
    local screenWidth = love.graphics.getWidth()
    local uiStartX = simAreaWidth  -- Começa no início da área de UI




    local uiStartX = simAreaWidth  -- Início da área de UI
    local uiPadding = 10          -- Margem interna
    local uiW = uiAreaWidth - 2 * uiPadding  -- Largura efetiva da UI

    -- Reinicia o layout na posição da área de UI + padding
    suit.layout:reset(uiStartX + uiPadding, 50)
    
    local rowHeight = 30
    local rowSpacing = 10

    -- Para os campos de entrada, vamos dividir a linha em duas colunas:
    local labelW = uiW * 0.3  -- 30% para o label
    local inputW = uiW * 0.7  -- 70% para o input

 -- Botão que ativa/desativa as opções de "Criar Caixa"
    if suit.Button("Criar Caixa", suit.layout:row(uiW, 40)).hit then
         showCreateBoxOptions = not showCreateBoxOptions
    end

    -- Se o drop down estiver ativo, exibe os inputs e o botão para criar a caixa
    if showCreateBoxOptions then
    suit.Label("Largura:", {align = "left"}, suit.layout:row(uiW, rowHeight))
    suit.Input(inputWidth, suit.layout:row(uiW, rowHeight))

    suit.Label("Altura:", {align = "left"}, suit.layout:row(uiW, rowHeight))
    suit.Input(inputHeight, suit.layout:row(uiW, rowHeight))

    suit.Label("Massa:", {align = "left"}, suit.layout:row(uiW, rowHeight))
    suit.Input(inputMass, suit.layout:row(uiW, rowHeight))

        if suit.Button("Criar", suit.layout:row(uiW, 40)).hit then
            local widthMeters = tonumber(inputWidth.text) or 1
            local heightMeters = tonumber(inputHeight.text) or 1
            local mass = tonumber(inputMass.text) or 1.0
            createbox(widthMeters, heightMeters, mass)
        end

         suit.layout:row(uiW, rowSpacing)  -- Espaço extra após os inputs
    end


    suit.layout:row(uiW, rowSpacing)

    if suit.Button("Excluir molas", suit.layout:row(uiW, 40)).hit then
        deleteAllSprings()
    end


    if suit.Button("Excluir Caixa", suit.layout:row(uiW, 40)).hit then
        if #boxes > 0 then
            destroybox(boxes[1].id)
        end
    end

    suit.Label("Valor de k:", {align = "left"}, suit.layout:row(uiW, rowHeight)) 
    suit.Input(inputSpringK, suit.layout:row(uiW, rowHeight)) 
    if suit.Button("Criar mola", suit.layout:row(uiW, 40)).hit then 
        local kValue = tonumber(inputSpringK.text) or 10 createSpring(kValue) 

    end 

    -- Atualiza o MouseJoint se houver uma mola sendo movida
    if mouseJoint then
        local mx, my = love.mouse.getPosition()
        mouseJoint:setTarget(mx, my)
    end


    -- Verifique se a mola está presa ao teto e a extremidade está fixa
    for _, spring in ipairs(springs) do
        if spring.joint1 then
            spring.body1:setPosition(spring.body1:getX(), spring.body1:getY())  -- Manter a extremidade 1 fixa
        end

        if spring.joint2 then
            spring.body2:setPosition(spring.body2:getX(), spring.body2:getY())  -- A extremidade 2 pode continuar livre
        end
    end


    -- Resetar valores antes de calcular novamente
    parallelForce = 0
    serieForce = 0
    totalK = 0
    connectedSprings = {}

    -- Primeiro, calcular apenas as forças sem chamar calculateSpringForce()
    for _, spring in ipairs(springs) do
        if spring.joint1 or spring.joint2 then
            local force = spring.k * ((spring.Length - spring.initialLength) / 64)
            parallelForce = parallelForce + force
            totalK = totalK + spring.k
            table.insert(connectedSprings, spring)
        end
    end

    -- Cálculo para sistema em série (evitar duplicação)
    if #connectedSprings > 1 then
        local serieK = 0
        for _, s in ipairs(connectedSprings) do
            serieK = serieK + (1 / s.k)
        end
        serieForce = 1 / serieK
    end

    -- Agora chamamos calculateSpringForce uma única vez para cada mola
    for _, spring in ipairs(springs) do
        calculateSpringForce(spring)
    end

end

function deleteAllSprings()
    if showTable == false then
        for _, spring in ipairs(springs) do
            -- Remove os corpos e juntas do mundo com verificação antes de destruir
            if spring.joint1 and not spring.joint1:isDestroyed() then
                spring.joint1:destroy()
                spring.joint1 = nil
            end
            if spring.joint2 and not spring.joint2:isDestroyed() then
                spring.joint2:destroy()
                spring.joint2 = nil
            end
            if spring.body1 then
                spring.body1:destroy()
            end
            if spring.body2 then
                spring.body2:destroy()
            end
        end
        -- Limpa a lista de molas
        springs = {}
        ceilingSnapOccupancy = {}
        bodySpringConnections = {}
    end
end

function getNearestCeilingSnappingPoint(mouseX, mouseY)
    local cx, cy = ceiling:getPosition()
    local halfWidth = largura / 2   -- 'largura' é a largura do teto
    local leftX = cx - halfWidth
    local nPoints = 8
    local segmentWidth = largura / nPoints
    local nearestPoint = nil
    local minDist = math.huge
    local nearestIndex = nil

    for i = 1, nPoints do
        local pointX = leftX + segmentWidth * (i - 0.5)
        local pointY = cy + (altura / 2)  -- pontos na borda inferior do teto
        local dx = pointX - mouseX
        local dy = pointY - mouseY
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist < minDist then
            minDist = dist
            nearestPoint = {x = pointX, y = pointY}
            nearestIndex = i
        end
    end

    if nearestPoint then
        nearestPoint.index = nearestIndex
    end

    return nearestPoint
end




function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        -- Primeiro, tenta mover uma mola
        for _, spring in ipairs(springs) do
            local x1, y1 = spring.body1:getPosition()
            local x2, y2 = spring.body2:getPosition()
            local distance1 = math.sqrt((x1 - x)^2 + (y1 - y)^2)
            local distance2 = math.sqrt((x2 - x)^2 + (y2 - y)^2)

            if distance1 < 15 then
                mouseJoint = love.physics.newMouseJoint(spring.body1, x, y)
                selectedObject = spring.body1
                selectedSpring = spring
                showTable = true
                return
            elseif distance2 < 15 then
                mouseJoint = love.physics.newMouseJoint(spring.body2, x, y)
                selectedObject = spring.body2
                return
            end
        end

        -- Verifica se o clique está dentro da hitbox atualizada de alguma caixa
        for _, box in ipairs(boxes) do
            local bx, by = box.body:getPosition()
            if x >= bx - box.width / 2 and x <= bx + box.width / 2 and
               y >= by - box.height / 2 and y <= by + box.height / 2 then
                mouseJoint = love.physics.newMouseJoint(box.body, x, y)
                selectedObject = box.body
                return
            end
        end
    elseif button == 2 then
        showTable = false
        selectedSpring = nil
        if not selectedObject then return end
        local mouseX, mouseY = x, y
        local isBox = false
        local selectedBox = nil
        for _, box in ipairs(boxes) do
            if selectedObject == box.body then
                isBox = true
                selectedBox = box
                break
            end
        end

        if isBox then
            -- Itera por TODAS as molas
            for _, spring in ipairs(springs) do
                -- Verifica proximidade com a CAIXA INTEIRA
                local springEndX, springEndY = spring.body2:getPosition()
                local boxX, boxY = selectedBox.body:getPosition()
                
                -- Calcula distância entre a extremidade da mola e o centro da caixa
                local dx = springEndX - boxX
                local dy = springEndY - boxY
                local distance = math.sqrt(dx*dx + dy*dy)
                
                -- Se estiver dentro do raio de 1.5x a largura da caixa
                if distance < (selectedBox.width * 1.5) then
                    if spring.joint2 == nil then
                        attachSpringToBox(spring, selectedBox)
                    end
                end
            end
        else
            
            for _, spring in ipairs(springs) do
                if selectedObject == spring.body1 then
                    local snapPoint = getNearestCeilingSnappingPoint(mouseX, mouseY)

                    if snapPoint and mouseY<80 then
                        local idx = snapPoint.index
                    
                            if not ceilingSnapOccupancy[idx] or ceilingSnapOccupancy[idx] < MAX_OCCUPANCY then
                                -- Reposiciona a extremidade da mola para o ponto magnético
                                spring.body1:setPosition(snapPoint.x, snapPoint.y)
                                local joint = love.physics.newWeldJoint(spring.body1, ceiling, snapPoint.x, snapPoint.y, false)
                                spring.joint1 = joint
                                -- Registra a ocupação
                                ceilingSnapOccupancy[idx] = (ceilingSnapOccupancy[idx] or 0) + 1
                                -- Opcional: armazene o índice no objeto da mola para liberar a ocupação depois
                                spring.snapIndex1 = idx
                                return
                            else
                                print("Ponto de snap ocupado:"..idx)
                                return
                            end
                    end
                end
            end
                local mx, my = love.mouse.getPosition()
                        for _, spring in ipairs(springs) do
                            for _, otherSpring in ipairs(springs)do
                            if otherSpring.id ~= spring.id then
                            local springEndX, springEndY= spring.body2:getPosition()
                            local otherSpringEndX, otherSpringEndY = otherSpring.body1:getPosition()
                            -- Calcula distância entre a extremidade da mola e o centro da caixa
                            local dx = otherSpringEndX - springEndX
                            local dy = otherSpringEndY - springEndY
                            local distance = math.sqrt(dx*dx + dy*dy)
                            if distance < 30 then
                                attachSpringToSpring(spring,otherSpring)
                            end
                        end
                    end
                end
        end
    end
end

function getNearestBoxSnapPoint(box, targetX, targetY)
    local bx, by = box.body:getPosition()
    local angle = box.body:getAngle()
    local halfWidth = box.width / 2
    local halfHeight = box.height / 2

    -- Calcula pontos ao longo da borda superior com precisão absoluta
    local nPoints = math.max(2, math.ceil(box.width / 64))
    local segmentWidth = box.width / (nPoints - 1)
    local minDist = math.huge
    local nearestPoint = nil

    for i = 0, nPoints - 1 do
        -- Posição local não rotacionada (borda superior centralizada)
        local localX = (-halfWidth + (segmentWidth * i))
        local localY = -halfHeight

        -- Aplica rotação usando a matriz de rotação do corpo
        local cos = math.cos(angle)
        local sin = math.sin(angle)
        local worldX = bx + (localX * cos - localY * sin)
        local worldY = by + (localX * sin + localY * cos)

        -- Calcula distância precisa
        local dx = worldX - targetX
        local dy = worldY - targetY
        local dist = math.sqrt(dx^2 + dy^2)

        if dist < minDist then
            minDist = dist
            nearestPoint = {
                x = worldX,
                y = worldY,
                localX = localX,
                localY = localY
            }
        end
    end

    return nearestPoint
end

function attachSpringToBox(spring, box)
    if not spring or not box then return end

    -- Obtém coordenadas exatas usando transformação local→global
    local springX, springY = spring.body2:getPosition()
    local snapPoint = getNearestBoxSnapPoint(box, springX, springY)
    if not snapPoint then return end

    -- Força o posicionamento usando o sistema de coordenadas do corpo
    local localX, localY = box.body:getLocalPoint(snapPoint.x, snapPoint.y)
    local finalX, finalY = box.body:getWorldPoint(localX, localY)

    -- Aplica posição e velocidade zero para evitar deriva
    spring.body2:setPosition(finalX, finalY)
    spring.body2:setLinearVelocity(0, 0)
    spring.body2:setAngularVelocity(0)

    -- Destroi e recria a junta com offset correto
    if spring.joint2 then spring.joint2:destroy() end
    local joint = love.physics.newRevoluteJoint(spring.body2, box.body, finalX, finalY, false)

    spring.joint2 = joint

    -- Se a caixa ainda não existir, cria ela
    if #boxes == 0 then
        print("Criando caixa porque foi conectada a uma mola")
        createbox(1, 1, 1.0) -- Criar a caixa com valores padrão (ou valores personalizados)
    end

    -- Atualiza imediatamente a física
    world:update(0.001)
end

function attachSpringToSpring(spring, otherSpring)
    if not spring or not otherSpring or spring == otherSpring then return end

    -- Obtém a posição de otherSpring.body2 (extremidade livre da outra mola)
    local spring2X, spring2Y = otherSpring.body1:getPosition()
    local snapPoint = getNearestSpringSnappingPoint(spring2X, spring2Y, spring)
    if not snapPoint then return end

    -- Calcula o ponto de snap corretamente para `body2` das duas molas
    local localX, localY = otherSpring.body1:getLocalPoint(snapPoint.x, snapPoint.y)
    local finalX, finalY = otherSpring.body1:getWorldPoint(localX, localY)

    -- Posiciona `otherSpring.body2` no ponto de conexão correto
    spring.body2:setPosition(finalX, finalY)
    spring.body2:setLinearVelocity(0, 0)
    spring.body2:setAngularVelocity(0)

    -- Cria o novo WeldJoint ligando `body2` das duas molas
    local newJoint = love.physics.newWeldJoint(otherSpring.body2,spring.body1 , finalX, finalY, false)
    
    -- Registra a conexão
    spring.joint2 = newJoint
    otherSpring.joint2 = newJoint  -- Ambas as molas compartilham a conexão

    -- Calcula o k equivalente para molas em série
    local k1 = spring.k
    local k2 = otherSpring.k
    local kEquivalente = 1 / ((1 / k1) + (1 / k2))

    -- Atualiza o k das molas conectadas
    spring.kEquivalente = kEquivalente
    otherSpring.kEquivalente = kEquivalente

    print("Conexão correta entre molas! K Equivalente:", kEquivalente)
end






function getNearestSpringSnappingPoint(body1X, body1Y, otherSpring)
    local nearestPoint = nil
    local minDist = math.huge
    local nearestIndex = nil
    -- Obtém a posição do body2 da mola externa
    local body2X, body2Y = otherSpring.body2:getPosition()
    
    -- Calcula a distância entre o body1 atual e o body2 da outra mola
    local dx = body2X - body1X
    local dy = body2Y - body1Y
    local dist = math.sqrt(dx * dx + dy * dy)

    -- Atualiza o ponto mais próximo se necessário
    if dist < minDist then
        minDist = dist
        nearestPoint = {x = body2X, y = body2Y}
        nearestIndex = i  -- Índice da mola na lista
    end

    -- if nearestPoint then
    --     nearestPoint.index = nearestIndex  -- Opcional: índice da mola mais próxima
    --     nearestPoint.spring = otherSpring[nearestIndex]  -- Referência direta (opcional)
    -- end

    return nearestPoint
end

function love.mousereleased(x, y, button, istouch, presses)
    -- Quando o mouse for liberado, remove o MouseJoint
    if button == 1 and mouseJoint then
        mouseJoint:destroy()
        mouseJoint = nil
        selectedObject = nil
    end
end

function drawBoxSnapPoints(box)
    local bx, by = box.body:getPosition()
    local angle = box.body:getAngle()
    local halfWidth = box.width / 2
    local topYLocal = -box.height / 2  -- coordenada local da borda superior

    -- Define o número de pontos proporcional à largura da caixa
    local ratio = box.width / largura  -- largura máxima é a do teto
    local nPoints = math.ceil(8 * ratio)
    if nPoints < 2 then nPoints = 2 end
    if nPoints > 8 then nPoints = 8 end

    local segmentWidth = box.width / nPoints
    local leftXLocal = -halfWidth

    for i = 1, nPoints do
        -- Coordenada local do ponto na borda superior
        local localX = leftXLocal + segmentWidth * (i - 0.5)
        local localY = topYLocal
        -- Rotaciona o ponto de acordo com o ângulo da caixa
        local rotatedX = localX * math.cos(angle) - localY * math.sin(angle)
        local rotatedY = localX * math.sin(angle) + localY * math.cos(angle)
        -- Converte para coordenadas mundiais
        local worldX = bx + rotatedX
        local worldY = by + rotatedY

        love.graphics.setColor(0, 1, 0)  -- cor verde para os pontos
        love.graphics.circle("fill", worldX, worldY, 3)
    end
end



function drawCeilingSnapPoints()
    local nPoints = 8
    local cx, cy = ceiling:getPosition()
    local halfWidth = largura / 2   -- largura do teto
    local leftX = cx - halfWidth
    local segmentWidth = largura / nPoints

    for i = 1, nPoints do
        local pointX = leftX + segmentWidth * (i - 0.5)
        local pointY = cy + (altura / 2)  -- pontos na parte inferior do teto
        love.graphics.setColor(1, 0, 0)  -- cor vermelha para os pontos
        love.graphics.circle("fill", pointX, pointY, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(i, pointX - 3, pointY + 8)
    end
end



function love.draw()
    local screenWidth, screenHeight = love.graphics.getDimensions()

    -- Desenha a faixa cinza da UI (lado direito)
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", simAreaWidth, 0, uiAreaWidth, screenHeight)

    -- Desenha o chão e o teto dentro da área de simulação (lado esquerdo)
    love.graphics.setColor(0.5, 1, 0.5) -- Verde para o chão
    love.graphics.polygon("fill", ground:getWorldPoints(ground:getFixtures()[1]:getShape():getPoints()))

    love.graphics.setColor(1, 0.5, 0.5) -- Vermelho para o teto
    love.graphics.polygon("fill", ceiling:getWorldPoints(ceiling:getFixtures()[1]:getShape():getPoints()))

    -- Desenha os pontos magnéticos no teto
    drawCeilingSnapPoints()

    -- Desenha os pesos
    for _, box in ipairs(boxes) do
        love.graphics.setColor(0.8, 0.8, 0) -- Cor amarela para o peso
        love.graphics.polygon("fill", box.body:getWorldPoints(box.shape:getPoints()))
        drawBoxSnapPoints(box)
    end
        -- Desenha as molas
    for _, spring in ipairs(springs) do

        local x1, y1 = spring.body1:getPosition()
        local x2, y2 = spring.body2:getPosition()

        love.graphics.setColor(0.8, 0.8, 0)  -- Cor amarela para as molas
        love.graphics.line(x1, y1, x2, y2)
        -- Desenha o contorno da hitbox das extremidades da mola (para visualização)
        love.graphics.setColor(1, 0.5, 0.5)  -- Cor preta para a borda
        love.graphics.circle("line", x1, y1, 10)  -- Para a extremidade 1
        love.graphics.setColor(0.5, 1, 0.5)  -- Cor preta para a borda
        love.graphics.circle("line", x2, y2, 10)  -- Para a extremidade 2


    end


    -- Exibir informações de todas as molas na parte inferior direita
    local infoWidth = 190
    local infoHeight = 90
    local margin = 10
    local startX = love.graphics.getWidth() - infoWidth - margin
    -- Começamos a partir da base da tela, subtraindo o espaço para o retângulo da primeira mola
    local startY = love.graphics.getHeight() - margin - infoHeight

    for i, spring in ipairs(springs) do
        local distanceMeters = spring.Length / 64
        local forceElastic = spring.k * distanceMeters

        local displayY = startY - (i - 1) * (infoHeight + margin)

        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", startX, displayY, infoWidth, infoHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Mola ID: " .. spring.id, startX + 10, displayY + 10)
        love.graphics.print("Distance: " .. string.format("%.2f", distanceMeters), startX + 10, displayY + 30)
        love.graphics.print("Force Elastic: " .. string.format("%.2f", forceElastic), startX + 10, displayY + 50)

        -- Exibir K Equivalente se houver conexão em série
        if spring.kEquivalente then
            love.graphics.print("K Equivalente: " .. string.format("%.2f N/m", spring.kEquivalente), startX + 10, displayY + 70)
        end
    end


    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    if #springs > 0 then
    local meter = 64
    local totalExtension = 0
    local totalForce = 0 
    
     -- supondo que parallelForce e serieForce sejam calculados corretamente ou substitua por uma soma das forças
    for _, spring in ipairs(springs) do
        local x1, y1 = spring.body1:getPosition()
        local x2, y2 = spring.body2:getPosition()
        local currentDistance = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        local extension = (currentDistance - spring.initialLength) / meter  -- em metros
        totalExtension = totalExtension + extension
        totalForce = totalForce + (spring.k * extension)

    end
    local kEquiv = totalForce/totalExtension
    local infoWidth2 = 250  
    local infoHeight2 = 90
    local margin2 = 10
    local infoX = love.graphics.getWidth() - infoWidth2 - margin2 - 200
    local infoY = love.graphics.getHeight() - margin2 - infoHeight2

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", infoX, infoY, infoWidth2, infoHeight2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Força Elástica Total: " .. string.format("%.2f N", totalForce), infoX + 10, infoY + 10)
    love.graphics.print("Distensão Total: " .. string.format("%.2f m", totalExtension), infoX + 10, infoY + 30)
    love.graphics.print("K Equivalente: " .. string.format("%.2f N/m", kEquiv), infoX + 10, infoY + 50)
end




    -- Desenha a interface SUIT
    suit.draw()
end

function createSpring(kValue)
    local springID = #springs + 1
    local springLength = 100  -- Distância inicial entre as extremidades da mola
    local k = kValue  -- Constante elástica (quanto maior, mais "rígida")
    local mass = (k*(springLength/64))/9.81
    
    -- Cria os dois corpos (extremidades da mola)
    local body1 = love.physics.newBody(world, love.graphics.getWidth() / 2 - springLength / 2, love.graphics.getHeight() / 2, "dynamic")
    local shape1 = love.physics.newCircleShape(10)  -- Forma circular para a extremidade
    local fixture1 = love.physics.newFixture(body1, shape1)
    
    local body2 = love.physics.newBody(world, love.graphics.getWidth() / 2 + springLength / 2, love.graphics.getHeight() / 2, "dynamic")
    local shape2 = love.physics.newCircleShape(10)  -- Forma circular para a extremidade
    local fixture2 = love.physics.newFixture(body2, shape2)
    body1:setMass(mass)
    body2:setMass(mass)
    -- Definir amortecimento angular
    body1:setAngularDamping(2)
    body2:setAngularDamping(2)
    
    --Adiciona um spring joint (mola) entre os dois corpos
    local spring = love.physics.newDistanceJoint(body1, body2, body1:getX(), body1:getY(), body2:getX(), body2:getY())
    spring:setDampingRatio(0.3)  -- Amortecimento para evitar oscilações abruptas
    spring:setFrequency(10)  -- Frequência da mola
    
    -- Armazena a mola
    table.insert(springs, {
       
        id = springID,
        body1 = body1,
        body2 = body2,
        connections = {},
        joint = spring,
        Length = springLength,
        initialLength = springLength,  -- Distância inicial
        k = k,  -- Constante elástica
        kEquivalente = 0
    })
end

function calculateSpringForce(spring)
    local g = 9.81
    local mass1 = spring.body1:getMass()
    local m_total = mass1  -- Começa com a massa da extremidade superior da mola

    -- Se houver uma caixa, adiciona a massa dela diretamente
    if spring.joint2 and #boxes > 0 then
        m_total = m_total + boxes[1].body:getMass()
    else
                -- Se não estiver conectada a uma caixa, mantém o comprimento inicial
        spring.Length = spring.initialLength
        spring.joint:setLength(spring.initialLength)
        return
    end

    -- Calcula a extensão da mola
    local extensionMeters = (m_total * g) / spring.k
    local extensionPixels = extensionMeters * 64
    local newLength = spring.initialLength + extensionPixels

    -- Atualiza a junta da mola
    spring.joint:setLength(newLength)
    spring.Length = extensionPixels

    -- Log para depuração
    print("calculateSpringForce chamado para mola ID:", spring.id, " - Massa total:", m_total)

    return extensionMeters, extensionPixels
end





function createbox(widthInMeters, heightInMeters, mass)
    local meter = 64  -- Fator de conversão: 1 metro = 64 pixels
    local width = widthInMeters * meter
    local height = heightInMeters * meter

    currentboxID = currentboxID + 1

    -- Cria o corpo da caixa (dinâmico) na posição central
    local boxBody = love.physics.newBody(world, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, "dynamic")

    -- Cria a forma retangular usando as medidas convertidas para pixels
    local boxShape = love.physics.newRectangleShape(width, height)
    local boxFixture = love.physics.newFixture(boxBody, boxShape)

    -- Define a massa da caixa
    boxBody:setMass(mass)

    boxBody:setLinearDamping(1)  -- Amortecimento linear
    boxBody:setAngularDamping(2) -- Amortecimento angular
    

    -- Armazena a caixa na lista
    table.insert(boxes, {
        id = currentboxID,
        body = boxBody,
        shape = boxShape,
        fixture = boxFixture,
        width = width,
        height = height
    })
end







function destroybox(boxID)
    if boxID then
        for i, box in ipairs(boxes) do
            if box.id == boxID then
                -- Verificar todas as molas para remover conexões com esta caixa
                for _, spring in ipairs(springs) do
                    if spring.joint2 then
                        spring.joint2:destroy()  -- Remove a conexão da mola com a caixa
                        spring.joint2 = nil      -- Apaga a referência para evitar erros
                    end
                end

                -- Destrói o corpo da caixa
                box.body:destroy()

                -- Remove a caixa da lista
                table.remove(boxes, i)

                print("Caixa ID " .. boxID .. " destruída e desconectada das molas.")
                break
            end
        end
    end
end
