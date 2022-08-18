itmId = 4584
itmSeed = itmId + 1

packList = {242}
packName = "world_lock"
packPrice = 2000
packLimit = 200

delayHarvest = 100
delayPlant = 100
delayPunch = 190
delayPlace = 130

storageSeed, doorSeed, patokanSeed = "", "", 16
storagePack, doorPack, patokanPack = "", "", 20

worldList = {}
doorFarm = ""

function warp(world,id)
    while getBot().world ~= world:upper() do
        sendPacket(3,"action|join_request\nname|"..world:upper())
        sleep(5000)
    end
    while getTile(math.floor(getBot().x / 32),math.floor(getBot().y / 32)).fg == 6 do
        sendPacket(3,"action|join_request\nname|"..world:upper().."|"..id:upper())
        sleep(1000)
    end
end

function reconnect(world,id,x,y)
    if getBot().state ~= 5 then
        while getBot().state ~= 5 do
            sleep(10000)
            if getBot().state == 5 then
                warp(world,id)
                sleep(100)
                if x and y then
                    findPath(x,y)
                    sleep(100)
                end
            end
        end
    end
end

function round(n)
    return n % 1 > 0.5 and math.ceil(n) or math.floor(n)
end

function droping(id,count,x,y)
    while findItem(id) >= count do
        local countId = 0
        local countTotal = 0
        local countStack = 0
        for _,obj in pairs(getObjects()) do
            if round(obj.x / 32) == x and math.floor(obj.y / 32) == y then
                if obj.id == id then
                    countId = countId + obj.count
                end
                countTotal = countTotal + obj.count
                countStack = countStack + 1
            end
        end
        if countStack < 20 then
            findPath(x - 1,y)
            sleep(100)
            drop(id,count)
            sleep(200)
        elseif countTotal < 4000 and (200 - (countId % 200)) > 0 then
            if findItem(id) >= (200 - (countId % 200)) then
                findPath(x - 1,y)
                sleep(100)
                drop(id,(200 - (countId % 200)))
                sleep(200)
            else
                findPath(x - 1,y)
                sleep(100)
                drop(id,findItem(id))
                sleep(200)
            end
        else
            break
        end
    end
end

function storePack()
    for _,pack in pairs(packList) do
        for _,tile in pairs(getTiles()) do
            if tile.fg == patokanPack then
                droping(pack,findItem(pack),tile.x,tile.y)
                sleep(100)
            end
        end
    end
end

function storeSeed(world)
    warp(storageSeed,doorSeed)
    sleep(100)
    for _,tile in pairs(getTiles()) do
        if tile.fg == patokanSeed then
            droping(itmSeed,100,tile.x,tile.y)
            sleep(100)
        end
    end
    warp(world,doorFarm)
    sleep(100)
end

function buy()
    if findItem(112) >= packPrice then
        warp(storagePack,doorPack)
        sleep(100)
        while findItem(112) >= packPrice do
            countBuy = 0
            while findItem(112) >= packPrice and countBuy < packLimit do
                sendPacket(2,"action|buy\nitem|"..packName)
                sleep(1000)
                countBuy = countBuy + 1
                reconnect(storagePack,doorPack)
            end
            storePack()
            sleep(100)
            reconnect(storagePack,doorPack)
        end
    end
end

function pnb(world)
    if findItem(itmId) > 0 then
        findPath(0,1)
        sleep(100)
        while findItem(itmId) > 0 and findItem(itmSeed) < 190 do
            while getTile(0,0).fg == 0 and getTile(0,0).bg == 0 do
                place(itmId,0,-1)
                sleep(delayPlace)
                reconnect(world,doorFarm,0,1)
            end
            while getTile(0,0).fg ~= 0 or getTile(0,0).bg ~= 0 do
                punch(0,-1)
                sleep(delayPunch)
                reconnect(world,doorFarm,0,1)
            end
            collect(2)
            reconnect(world,doorFarm,0,1)
        end
    end
end

function plant(world)
    for _,tile in pairs(getTiles()) do
        if tile.fg ~= 0 and tile.fg ~= itmSeed and tile.fg ~= 12 and getTile(tile.x,tile.y - 1).fg == 0 then
            findPath(tile.x,tile.y - 1)
            while getTile(tile.x,tile.y - 1).fg == 0 do
                place(itmSeed,0,0)
                sleep(delayPlant)
                reconnect(world,doorFarm,tile.x,tile.y - 1)
            end
            if findItem(itmSeed) == 0 then
                break
            end
        end
    end
    if findItem(itmSeed) >= 100 then
        storeSeed(world)
        sleep(100)
    end
end

function harvest(world)
    for _,tile in pairs(getTiles()) do
        if tile.fg ~= 0 and tile.fg ~= itmSeed and tile.fg ~= 12 and getTile(tile.x,tile.y - 1).ready then
            findPath(tile.x,tile.y - 1)
            while getTile(tile.x,tile.y - 1).ready do
                punch(0,0)
                sleep(delayHarvest)
                reconnect(world,doorFarm,tile.x,tile.y - 1)
            end
            collect(2)
        end
        if findItem(itmId) >= 190 then
            pnb(world)
            sleep(100)
            plant(world)
            sleep(100)
        end
    end
end

for _,world in pairs(worldList) do
    warp(world,doorFarm)
    sleep(100)
    harvest(world)
    sleep(100)
    pnb(world)
    sleep(100)
    plant(world)
    sleep(100)
    buy()
    sleep(100)
end